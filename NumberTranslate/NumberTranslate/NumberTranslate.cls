/// <html>
/// <head><title>NumberTranslate.NumberTranslate</title></head>
/// <h1>NumberTranslate</h1>
/// <h2>Overview</h2>
/// <p>the aim of this function is to convert numbers into text.</p>
/// <p>It allows a maximum number of 15 digits.</p>
/// <p>The translation is done in several languages. The allowed languages are</p>
/// <p><ul>
/// <li><b>es</b>: Spanish</li>
/// <li><b>en</b>: English</li>
/// <li><b>ca</b>: Catalan</li>
/// </ul></p>
/// <p>The function also allows to treat the numbers of 10^9 (millards) in English-speaking countries format. See the following link <a href="https://en.wikipedia.org/wiki/Billion">Billion Wikipedia</a></p>
/// <h2>Example</h2>
/// <pre>
/// USER> w ##class(NumberTranslate.NumberTranslate).GetText(123,.tSc)
/// one hundred and twenty-three
/// USER> w ##class(NumberTranslate.NumberTranslate).GetText(123,.tSc,"es")
/// ciento veintitres
/// USER> w ##class(NumberTranslate.NumberTranslate).GetText(123,.tSc,"ca")
/// cent vint-i-tres
/// USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000,.tSc,"en",1)
/// one billion
/// USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000,.tSc,"en",0)
/// one thousand millions
/// USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000000,.tSc,"en",1)
/// one trillion
/// USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000000,.tSc,"en",0)
/// one billion
/// </pre>
/// <p>In case of error, you can catch the error with the status variable
/// <pre>
/// USER> set text=##class(NumberTranslate.NumberTranslate).GetText(123,.tSc,"fr") 
/// USER> if ('tSc) { w $System.Status.GetErrorText(tSc) } else { w text }        
/// ERROR #420: Lang fr not exists
/// </pre>
/// </html>
Class NumberTranslate.NumberTranslate Extends %RegisteredObject
{

/// Internal method to get trio of digit and translate according to language
Method Trio(pTrio As %String) As %String
{
	set obj=..%New()
	if (^NumberTranslate("Current","debug"))
	{
		w "--------------",!
		w "Value trio:",?25,pTrio,!
	}
	set lcent = $EXTRACT(pTrio,1,1)
	set lten = $EXTRACT(pTrio,2,2)
	set lunit = $EXTRACT(pTrio,3,3)
	
	set lang = ^NumberTranslate("Current","lang")
	
	set figure = ""
	
	// First figure (cent)
	if (lcent>0)
	{
	set figure=figure_$SELECT(((lten=0)&&(lunit=0)):^NumberTranslate("Config","lang",lang,"hundred"),
			1:^NumberTranslate("Config","lang",lang,"hundred",lcent))
	}
	
	if (lcent>0)&&((lten>0)||(lunit>0))
	{
		set figure=figure_^NumberTranslate("Config","lang",lang,"concat-cents")
	}
	
	// Second figure (tens)
	if ((lten>=3)&&(lten<=9))
	{
		set figure = figure_$SELECT(lunit=0:obj.GetDigit(lten*10)_" ",lunit>0:obj.GetDigit(lten*10)_^NumberTranslate("Config","lang",lang,"concat-tens"))
	} elseif (lten = 2)
	{
		set figure = figure_$SELECT(lunit=0:^NumberTranslate("Config","lang",lang,"unit",29)_" ",1:obj.GetDigit(lten*10))
		// Condition only for Spanish and twenty
		if (lang'="es")&&(lunit>0)
		{
			set figure = figure_^NumberTranslate("Config","lang",lang,"concat-tens")
		}
	} elseif (lten = 1)
	{
		set figure = figure_" "_obj.GetDigit((lten*10)+lunit)_" "
	}
		
	// Third figure (unit)
	if ((lunit>0)&&(lten'=1))
	{
		set figure = figure_obj.GetDigit(lunit)
	}


	// Remove all double spaces
	set figure=$Replace(figure,"  "," ")
	k obj
	quit figure
}

/// Internal method to get the text of digit
Method GetDigit(pNumber As %Integer) As %String
{
	set sCurrent = ""
	set lang = ^NumberTranslate("Current","lang")
		
	if (pNumber <= 20)
	{
		// From 1 to 20 is the same than position of Unit
		set sCurrent = ^NumberTranslate("Config","lang",lang,"unit",pNumber)
	}
	else
	{
		set lNumber = pNumber - 30
		set lPos = 0
		if (lNumber < 0)
		{
			set lNumber = lNumber * -1
			set lPos = (lNumber/10) + 21
		} 
		else 
		{
			if (lNumber = 0)
			{
				set lPos = 21
			} 
			else
			{
				set lPos = (lNumber/10) + 21
			}
		}
		set sCurrent = ^NumberTranslate("Config","lang",lang,"unit",lPos)
	}
		
	quit sCurrent
}

/// Translate a number to text
ClassMethod GetText(pNumber As %Decimal, Output pStatus As %Status, pLang As %String = "en", pEngBillion As %Boolean = 0) As %String	
{
	set obj=..%New()
	set pStatus = $$$OK
	set tResult = ""
	// Check if code is installed
	if ($Get(^NumberTranslate("Config"))'=1)
	{
		do ##class(NumberTranslate.Initialize).Initialize()
	}

	//Allowed langs ^NumberTranslate("Config","lang")
	if ('$listfind($LISTFROMSTRING(^NumberTranslate("Config","lang"),";"),pLang))
	{
		SET pStatus = $System.Status.Error(420,"Lang",pLang)
		Quit tResult
	}
	
	set ^NumberTranslate("Current","lang")=pLang
	set ^NumberTranslate("Current","culture")=$CASE(pEngBillion,1:"en",0:"")
	
	set number = $System.SQL.TOCHAR(pNumber,"000000000000000")
	set billion=$Extract(number,0,4)
	set millard=$Extract(number,5,7)
	set million=$Extract(number,8,10)
	set thousand=$Extract(number,11,13)
	set cents=$Extract(number,14,16)
	
	if (^NumberTranslate("Current","debug"))
	{
		w "Number to process:",?25,number,!
		w "(EUR) Billion:",?25,billion,!
		w "Millard:",?25,millard,!
		w "Million:",?25,million,!
		w "Thousand:",?25,thousand,!
		w "Cents:",?25,cents,!
	}
	
	// Five blocks, watch out with billion USA and billion EUR
	for block=1:1:5
	{
		if (block=1) // (EUR) Billion / (ENG) Trillion
		{
			// Acording to culture, the text could be trillion or billion
			set textBlock=$CASE(pEngBillion,1:^NumberTranslate("Config","lang",pLang,"trillion"),0:^NumberTranslate("Config","lang",pLang,"billion"))
			set textBlocks=$CASE(pEngBillion,1:^NumberTranslate("Config","lang",pLang,"trillions"),0:^NumberTranslate("Config","lang",pLang,"billions"))
			
			set tResult=tResult_" "_$SELECT($Number(billion)=1:^NumberTranslate("Config","lang",pLang,"unit")_" "_textBlock,$Number(billion)>1:obj.Trio(billion)_" "_textBlocks,1:"")
		}
		if (block=2) // (EUR) Thousand million / (ENG) Billion
		{
			// Acording to culture, the text could be billion or thousand (of billion)
			set textBlock=$CASE(pEngBillion,1:^NumberTranslate("Config","lang",pLang,"billion"),0:^NumberTranslate("Config","lang",pLang,"thousand"))
			set textBlocks=$CASE(pEngBillion,1:^NumberTranslate("Config","lang",pLang,"billions"),0:^NumberTranslate("Config","lang",pLang,"thousand"))
			
			set tResult=tResult_" "_$SELECT($Number(millard)=1:^NumberTranslate("Config","lang",pLang,"unit")_" "_textBlock, $Number(millard)>1:obj.Trio(millard)_" "_textBlocks, 1:"")
			
		}
		if (block=3) // Million
		{
			set textBlock=^NumberTranslate("Config","lang",pLang,"million")
			set textBlocks=^NumberTranslate("Config","lang",pLang,"millions")
			
			set tResult=tResult_" "_$SELECT($Number(million)=1:^NumberTranslate("Config","lang",pLang,"unit")_" "_textBlock, 
				$Number(million)>1:obj.Trio(million)_" "_textBlocks, 
				$Number(millard)>0: $SELECT(pEngBillion=1:" ",1:" "_textBlocks),1:"")
		}
		if (block=4) // Thousand
		{
			set textBlock=^NumberTranslate("Config","lang",pLang,"thousand")
			
			set tResult=tResult_" "_$SELECT($Number(thousand)=1:textBlock, $Number(thousand)>1:obj.Trio(thousand)_" "_textBlock,1:"")
		}
		if (block=5) // Cents
		{
			set tResult=tResult_" "_obj.Trio(cents)
		}
	}
	
	k obj
	set tResult = $ZSTRIP($Replace(tResult,"  "," "),"<>"," ")
	Quit tResult
}

}
