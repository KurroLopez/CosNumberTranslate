Class NumberTranslate.NumberTranslate Extends %RegisteredObject
{

ClassMethod Trio(pTrio As %String) As %String
{
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
		set figure = figure_$SELECT(lunit=0:..GetDigit(lten*10)_" ",lunit>0:..GetDigit(lten*10)_^NumberTranslate("Config","lang",lang,"concat-tens"))
	} elseif (lten = 2)
	{
		set figure = figure_$SELECT(lunit=0:^NumberTranslate("Config","lang",lang,"unit",29)_" ",1:..GetDigit(lten*10))
		// Condition only for Spanish and twenty
		if (lang'="es")&&(lunit>0)
		{
			set figure = figure_^NumberTranslate("Config","lang",lang,"concat-tens")
		}
	} elseif (lten = 1)
	{
		set figure = figure_" "_..GetDigit((lten*10)+lunit)_" "
	}
		
	// Third figure (unit)
	if ((lunit>0)&&(lten'=1))
	{
		set figure = figure_..GetDigit(lunit)
	}


	// Remove all double spaces
	set figure=$Replace(figure,"  "," ")
	
	quit figure
}

ClassMethod GetDigit(pNumber As %Integer) As %String
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

Method GetText(pNumber As %Decimal, Output pResult As %String, pLang As %String = "es", pEngBillion As %Boolean = 0) As %Status
{
	set pResult = ""
	// Check if code is installed
	if ($Get(^NumberTranslate("Config"))'=1)
	{
		do ##class(NumberTranslate.Initialize).Initialize()
	}

	//Allowed langs ^NumberTranslate("Config","lang")
	if ('$listfind($LISTFROMSTRING(^NumberTranslate("Config","lang"),";"),pLang))
	{
		QUIT $$$ERROR("Lang '"_pLang_"' is not a valid language.")
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
			
			set pResult=pResult_" "_$SELECT($Number(billion)=1:^NumberTranslate("Config","lang",pLang,"unit")_" "_textBlock,$Number(billion)>1:..Trio(billion)_" "_textBlocks,1:"")
		}
		if (block=2) // (EUR) Thousand million / (ENG) Billion
		{
			// Acording to culture, the text could be billion or thousand (of billion)
			set textBlock=$CASE(pEngBillion,1:^NumberTranslate("Config","lang",pLang,"billion"),0:^NumberTranslate("Config","lang",pLang,"thousand"))
			set textBlocks=$CASE(pEngBillion,1:^NumberTranslate("Config","lang",pLang,"billions"),0:^NumberTranslate("Config","lang",pLang,"thousand"))
			
			set pResult=pResult_" "_$SELECT($Number(millard)=1:^NumberTranslate("Config","lang",pLang,"unit")_" "_textBlock, $Number(millard)>1:..Trio(millard)_" "_textBlocks, 1:"")
			
		}
		if (block=3) // Million
		{
			set textBlock=^NumberTranslate("Config","lang",pLang,"million")
			set textBlocks=^NumberTranslate("Config","lang",pLang,"millions")
			
			set pResult=pResult_" "_$SELECT($Number(million)=1:^NumberTranslate("Config","lang",pLang,"unit")_" "_textBlock, $Number(million)>1:..Trio(million)_" "_textBlocks, $Number(millard)>0:" "_textBlocks,1:"")
		}
		if (block=4) // Thousand
		{
			set textBlock=^NumberTranslate("Config","lang",pLang,"thousand")
			
			set pResult=pResult_" "_$SELECT($Number(thousand)=1:textBlock, $Number(thousand)>1:..Trio(thousand)_" "_textBlock,1:"")
		}
		if (block=5) // Cents
		{
			set pResult=pResult_" "_..Trio(cents)
		}
	}

	set pResult = $ZSTRIP($Replace(pResult,"  "," "),"<>"," ")
	Quit $$$OK
}

}
