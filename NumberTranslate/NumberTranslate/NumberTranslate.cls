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
Class NumberTranslate.NumberTranslate Extends %RegisteredObject [ Not ProcedureBlock ]
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
	quit:pLang="ru" $piece(..WriteSumma(pNumber), " руб")
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

/// перевод суммы в пропись
ClassMethod WriteSumma(summa As %Decimal = "") As %String
{
 ; ПЕРЕВОД СУММЫ В ПРОПИСЬ;07:02 PM  14 Jan 1995, L=3598
 ;
 new SUMMA,SUMMAP,%X,%X0,%X1,R0,R1,VV,V2,V3,V
 set SUMMA=summa
 I +SUMMA'<1000000000000 S SUMMAP=SUMMA G END0 ;### 
 I +SUMMA<0 S SUMMA=-SUMMA
 S %X=+$P(SUMMA,".",1),SUMMAP="",VV=0
 ;I %X=0 S SUMMAP="ноль рублей"
 I %X=0 S SUMMAP="ноль "
 I %X>0 D PRUBL
 S V2=$E(%X,$L(%X)-1),V3=$E(%X,$L(%X))  
 I V3=1,V2'=1 S SUMMAP=SUMMAP_" рубль",VV=1
 I ((V3=2)!(V3=3)!(V3=4))&(V2'=1) S SUMMAP=SUMMAP_" рубля",VV=1
 I ((V3=1)!(V3=2)!(V3=3)!(V3=4))&(V2=1) S SUMMAP=SUMMAP_" рублей",VV=1
 I V3>4 S SUMMAP=SUMMAP_" рублей",VV=1
 I VV=0 S SUMMAP=SUMMAP_" рублей"
 S %X=$P(SUMMA,".",2) I %X="" S %X="00"
 I %X?1N S %X=%X_"0",(V1,V)="0"
 I %X?2N S V1=$E(%X,1,1),V=$E(%X,2,2)
R1 I (V="1")&(V1'="1") S SUMMAP=SUMMAP_" "_%X_" копейка"
 I ((V="2")!(V="3")!(V="4"))&(V1'="1") S SUMMAP=SUMMAP_" "_%X_" копейки"
 I ((V'="1")&(V'="2")&(V'="3")&(V'="4"))!(V1="1") S SUMMAP=SUMMAP_" "_%X_" копеек"
 I $E(SUMMAP)=" " S SUMMAP=$E(SUMMAP,2,255)
 S SUMMAP=$TR($E(SUMMAP),"одтчпшсвн","ОДТЧПШСВН")_$E(SUMMAP,2,255)
END0 K %X,%X0,%X1,R0,R1
 Q (SUMMAP) ;1
 ;-
PRUBL ; РУБЛИ   
 D PMILR,PMILE,PtYS,PEDIN
 Q  ;PRUBL
 ;-
PMILR ;МИЛЛИАРД
 S %X0=%X\1000000000 Q:%X0=0  ;###
 D PSoT,PDES
 ;S SUMMAP=SUMMAP_"миллион"_$S(%X0#10=1:"",%X0#10>1&(%X0#10<5):"а",1:"ов")_" "
RRR3 S SUMMAP=SUMMAP_" миллиард"_$S(%X0#100=0:"ов",%X0#100>10&(%X0#100<21):"ов",%X0#10>1&(%X0#10<5):"а",%X0#10=1:"",1:"ов")_" "
 K R3
 Q  ;PMILR
 ;-
PMILE ;МИЛЛИОНЫ
 ;S %X0=%X\1000000 Q:%X0=0  ;###
 S %X0=%X#1000000000\1000000 Q:%X0=0  ;###
 D PSoT,PDES
 ;S SUMMAP=SUMMAP_"миллион"_$S(%X0#10=1:"",%X0#10>1&(%X0#10<5):"а",1:"ов")_" "
R3 S SUMMAP=SUMMAP_" миллион"_$S(%X0#100=0:"ов",%X0#100>10&(%X0#100<21):"ов",%X0#10>1&(%X0#10<5):"а",%X0#10=1:"",1:"ов")_" "
 K R3
 Q  ;PMILE
 ;-
PtYS ;ТЫСЯЧИ
 S %X0=%X#1000000\1000 Q:%X0=0  ;###
 D PSoT,PDES
 S %X1=$E(SUMMAP,$L(SUMMAP)-2,$L(SUMMAP))
 I %X1="ва " S SUMMAP=$E(SUMMAP,1,$L(SUMMAP)-3)_"ве "
 I %X1="ин " S SUMMAP=$E(SUMMAP,1,$L(SUMMAP)-3)_"на "
QQ S SUMMAP=SUMMAP_"тысяч"_$S(%X0#100=11:"",%X0#100=12:"",%X0#100=13:"",%X0#100=14:"",%X0#10=1:"а",%X0#10>1&(%X0#10<5):"и",1:"")_" "
 K R4,R5,R6
 Q  ;PtYS
 ;-
PEDIN ;ЕДИНИЦЫ В ОСТАТКЕ
 S %X0=%X#1000 Q:%X0=0  ;###
 D PSoT,PDES
 Q  ;PtDIN
 ;-
PSoT ;СОТНИ
 S %X1=%X0\100 Q:%X1=0  ;###
R7 S S1="сто"
R8 S S2="двести"
R9 S S3="триста"
R10 S S4="четыреста"
R11 S S5="пятьсот"
R12 S S6="шестьсот"
R13 S S7="семьсот"
R14 S S8="восемьсот"
R15 S S9="девятьсот"
 S SUMMAP=SUMMAP_$S(%X1=1:S1,%X1=2:S2,%X1=3:S3,%X1=4:S4,%X1=5:S5,%X1=6:S6,%X1=7:S7,%X1=8:S8,%X1=9:S9)_" "
 K S1,S2,S3,S4,S5,S6,S7,S8,S9
 Q  ;PSoT
 ;-
PDES ;ДЕСЯТКИ
 S %X1=%X0#100\10 Q:%X=0  ;###
 I %X1=1 D PDC Q  ;###
R17 S D2="двадцать"
R18 S D3="тридцать"
R19 S D4="сорок"
R20 S D5="пятьдесят"
R21 S D6="шестьдесят"
R22 S D7="семьдесят"
R23 S D8="восемьдесят"
R24 S D9="девяносто"
 S SUMMAP=SUMMAP_$S(%X1=2:D2,%X1=3:D3,%X1=4:D4,%X1=5:D5,%X1=6:D6,%X1=7:D7,%X1=8:D8,%X1=9:D9,1:"")_" "
 K D2,D3,D4,D5,D6,D7,D8,D9
 D PoDIN
 Q  ;PDES
 ;-
PDC ;
 S %X1=%X0#10
R25 S F0="десять"
R26 S F1="одиннадцать"
R27 S F2="двенадцать"
R28 S F3="тринадцать"
R29 S F4="четырнадцать"
R30 S F5="пятнадцать"
R31 S F6="шестнадцать"
R32 S F7="семнадцать"
R33 S F8="восемнадцать"
R34 S F9="девятнадцать"
 S SUMMAP=SUMMAP_$S(%X1=0:F0,%X1=1:F1,%X1=2:F2,%X1=3:F3,%X1=4:F4,%X1=5:F5,%X1=6:F6,%X1=7:F7,%X1=8:F8,%X1=9:F9)
 K F0,F1,F2,F3,F4,F5,F6,F7,F8,F9  
 Q  ;PDC
 ;-
PoDIN ;ЕДИНИЦЫ
 S %X1=%X0#10 I %X1=0 Q  ;###
 S SUMMAP=SUMMAP_$S(%X1=1:"один",%X1=2:"два",%X1=3:"три",%X1=4:"четыре",%X1=5:"пять",%X1=6:"шесть",%X1=7:"семь",%X1=8:"восемь",%X1=9:"девять",1:"")_" "
 K E1,E2,E3,E4,E5,E6,E7,E8,E9
 Q  ;PoDIN
}
}
