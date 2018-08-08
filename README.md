# NumberTranslate

[![Gitter](https://img.shields.io/badge/article-on%20community-blue.svg)](https://community.intersystems.com/post/translate-number-text) 

Convert number to text for Cache Object Script (Intersystems)
### Overview

the aim of this function is to convert numbers into text.
It allows a maximum number of 15 digits.
The translation is done in several languages. The allowed languages are

- **es:** Spanish
- **en:** English
- **ca:** Catalan
- **ru:** Russian

The function also allows to treat the numbers of 10^9 (millards) in English-speaking countries format. See the following link [Billion Wikipedia](https://en.wikipedia.org/wiki/Billion)

### Example
```sh
USER> w ##class(NumberTranslate.NumberTranslate).GetText(123,.tSc)
one hundred and twenty-three
USER> w ##class(NumberTranslate.NumberTranslate).GetText(123,.tSc,"es")
ciento veintitres
USER> w ##class(NumberTranslate.NumberTranslate).GetText(123,.tSc,"ca")
cent vint-i-tres
USER> w ##class(NumberTranslate.NumberTranslate).GetText(123,.tSc,"ru")
Сто двадцать три
USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000,.tSc,"en",1)
one billion
USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000,.tSc,"en",0)
one thousand millions
USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000000,.tSc,"en",1)
one trillion
USER> w ##class(NumberTranslate.NumberTranslate).GetText(1000000000000,.tSc,"en",0)
one billion
```

In case of error, you can catch the error with the status variable

```sh
USER> set text=##class(NumberTranslate.NumberTranslate).GetText(123,.tSc,"fr") 
USER> if ('tSc) { w $System.Status.GetErrorText(tSc) } else { w text }        
ERROR #420: Lang fr not exists
```

### Version history
2018-08-07 [Version 1.1](https://github.com/KurroLopez/CosNumberTranslate/blob/master/Version/CosNumberTranslation_v1.1.xml) - Russian translate

2018-06-29 [Version 1.0](https://github.com/KurroLopez/CosNumberTranslate/blob/master/Version/CosNumberTranslation_v1.0.xml) - Initial version
