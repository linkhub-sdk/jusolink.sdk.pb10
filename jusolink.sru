$PBExportHeader$jusolink.sru
forward
global type jusolink from nonvisualobject
end type
end forward

global type jusolink from nonvisualobject
end type
global jusolink jusolink

type variables
private:
Constant String ServiceID = "JUSOLINK"
constant string ServiceURL= "https://juso.linkhub.co.kr"
constant string APIVersion = "1.0"

protected:
token in_token
authority in_authority
jusolinkexception exception

public:
string linkID
string secretKey
string scopes[]

end variables

forward prototypes
private function authority getauthority () throws jusolinkexception
protected function string getserviceurl ()
private function string getsessiontoken (string forwardip) throws jusolinkexception
public function double getbalance () throws jusolinkexception
protected function any parsejson (string inputjson) throws jusolinkexception
protected function any httpget (string url) throws jusolinkexception
public function decimal getunitcost () throws jusolinkexception
public function searchresult search(string index, integer PageNum, integer PerPage) throws jusolinkexception
public function searchresult search(string index, integer PageNum, integer PerPage, boolean noSuggest, boolean noDiff) throws jusolinkexception
protected function string of_replaceall (string as_oldstring, string as_findstr, string as_replace)
public function searchresult tojusoinfo(ref oleobject dic)
function string urlencode (string target_string) 
end prototypes

private function authority getauthority () throws jusolinkexception;if isnull(in_authority) then
	if isnull(linkid) or linkID = "" then throw exception.setCodeNMessage(-99999999,"링크아이디가 입력되지 않았습니다.")
	if isnull(secretKey) or secretKey = "" then throw exception.setCodeNMessage(-99999999,"비밀키가 입력되지 않았습니다.")
	in_authority = create authority
	in_authority.linkid = linkid
	in_authority.secretkey = secretKey
end if

return in_authority
end function

protected function string getserviceurl();
	return serviceurl
end function

private function string getsessiontoken (string forwardip) throws jusolinkexception;
boolean changed,expired
DateTime now

expired = true

if not changed and isnull(in_token) = false then
	try 
		now = DateTime(date(mid(getAuthority().getTime(),1,10)) ,time( mid(getAuthority().getTime(),12,8)))
	catch (linkhubexception ex)
		throw exception.setCodeNMessage(ex.getcode(),ex.getmessage())
	end try
	expired = DateTime(date(mid(in_token.expiration,1,10)) ,time( mid(in_token.expiration,12,8))) <  now
end if

if expired then
	try
		in_token = getauthority().gettoken(ServiceID,"",scopes,forwardip)
	catch (linkhubexception le)
		throw exception.setCodeNMessage(le.getcode(),le.getmessage())
	end try
end if

return in_token.session_token
end function

public function double getbalance () throws jusolinkexception;try
	return  getAuthority().getPartnerBalance(getsessionToken(""),ServiceID)
catch(linkhubexception le)
	throw exception.setcodenmessage(le.getcode(),le.getmessage())
end try
end function

protected function any parsejson (string inputjson) throws jusolinkexception;try
	return getauthority().parsejson(inputjson)
catch(linkhubexception le)
	throw exception.setcodenmessage(le.getcode(),le.getmessage())
end try
end function

protected function any httpget (string url) throws jusolinkexception;OLEObject lo_httpRequest,dic
any anyReturn
string ls_result

lo_httpRequest = CREATE OLEObject
if lo_httpRequest.ConnectToNewObject("MSXML2.XMLHTTP.6.0") <> 0 then throw exception.setCodeNMessage(-99999999,"HttpRequest Create Fail.")
lo_httpRequest.open("GET",getServiceURL() + url,false)
lo_httpRequest.setRequestHeader("Authorization","Bearer " + getsessionToken(""))
lo_httpRequest.setRequestHeader("x-api-version",APIVersion)
lo_httpRequest.setRequestHeader("Accept-Encoding", "gzip,deflate")
lo_httpRequest.send()

ls_result = string(lo_httpRequest.ResponseText)

if lo_httpRequest.Status <> 200 then 
	dic = parsejson(ls_result)
	exception.setCodeNMessage(dic.Item("code"),dic.Item("message"))
	lo_httpRequest.DisconnectObject()
	destroy lo_httpRequest
	dic.DisconnectObject()
	destroy dic
	throw exception
end if

lo_httpRequest.DisconnectObject()
destroy lo_httpRequest

anyReturn = parsejson(ls_result)
return anyReturn

end function

public function decimal getunitcost () throws jusolinkexception;decimal unitcost
oleObject result

result = httpget("/Search/UnitCost")
unitcost = dec(result.Item("unitCost"))
result.DisconnectObject()
destroy result

return unitcost
end function

public function searchresult search(string index, integer PageNum, integer PerPage) throws jusolinkexception; return search(index, PageNum, PerPage, false, false)
end function

public function searchresult search(string index, integer PageNum, integer PerPage, boolean noSuggest, boolean noDiff) throws jusolinkexception;searchresult result
oleobject dic
int i
string url

if Not(isnull(PageNum)) and PageNum <1 then PageNum = 1

if Not(isnull(PerPage)) then
	if(PerPage <0) then PerPage = 20
end if

url = "/Search?Searches="

if isnull(index) or index = "" then throw exception.setCodeNMessage(-99999999,"검색어가 입력되지 않았습니다.")

url += urlencode(index)
url += "&PageNum=" + string(PageNum)
url += "&PerPage=" + string(PerPage)

if noSuggest then url += "&noSuggest=true"
if noDiff then url += "&noDifferential=true"

dic = httpget(url)
result = tojusoinfo(dic)

if Not(IsNull(dic.Item("juso"))) then
	oleobject toDestory[]
	toDestory = dic.Item("juso")
	
	for i = 1 to upperbound(toDestory)
		toDestory[i].DisconnectObject()
		destroy toDestory[i]
	next
end if

dic.DisconnectObject()
destroy dic

return result
end function

protected function string of_replaceall (string as_oldstring, string as_findstr, string as_replace);String ls_newstring
Long ll_findstr, ll_replace, ll_pos

ll_findstr = Len(as_findstr)
ll_replace = Len(as_replace)

ls_newstring = as_oldstring
ll_pos = Pos(ls_newstring, as_findstr)

Do While ll_pos > 0
	ls_newstring = Replace(ls_newstring, ll_pos, ll_findstr, as_replace)
	ll_pos = Pos(ls_newstring, as_findstr, (ll_pos + ll_replace))
Loop

Return ls_newstring

end function

public function searchresult tojusoinfo(ref oleobject dic);searchresult result
Integer i
 
result.searches = string(dic.Item("searches"))
result.suggest = string(dic.Item("suggest"))
result.listSize = Integer(dic.Item("listSize"))
result.numFound = Integer(dic.Item("numFound"))
result.totalPage = Integer(dic.Item("totalPage"))
result.page = Integer(dic.Item("page"))

if Not(isNull(dic.Item("deletedWord"))) then
	result.deletedWord = dic.Item("deletedWord")	
end if

if isnull(dic.Item("chargeYN")) then
	result.chargeYN = False
else
	result.chargeYN = dic.Item("chargeYN")
end if
	
if Not(isNull(dic.Item("sidoCount"))) then
	oleobject sidoArray 
	sidoArray = dic.Item("sidoCount")
	if Not(isNull(sidoArray.Item("GYEONGGI"))) then result.sidoCount.GYEONGGI = sidoArray.Item("GYEONGGI")
	if Not(isNull(sidoArray.Item("GYEONGSANGBUK"))) then result.sidoCount.GYEONGSANGBUK = sidoArray.Item("GYEONGSANGBUK")
	if Not(isNull(sidoArray.Item("GYEONGSANGNAM"))) then result.sidoCount.GYEONGSANGNAM = sidoArray.Item("GYEONGSANGNAM")
	if Not(isNull(sidoArray.Item("SEOUL"))) then result.sidoCount.SEOUL = sidoArray.Item("SEOUL")
	if Not(isNull(sidoArray.Item("JEOLLANAM"))) then result.sidoCount.JEOLLANAM = sidoArray.Item("JEOLLANAM")
	if Not(isNull(sidoArray.Item("CHUNGCHEONGNAM"))) then result.sidoCount.CHUNGCHEONGNAM = sidoArray.Item("CHUNGCHEONGNAM")
	if Not(isNull(sidoArray.Item("JEOLLABUK"))) then result.sidoCount.JEOLLABUK = sidoArray.Item("JEOLLABUK")
	if Not(isNull(sidoArray.Item("BUSAN"))) then result.sidoCount.BUSAN = sidoArray.Item("BUSAN")
	if Not(isNull(sidoArray.Item("GANGWON"))) then result.sidoCount.GANGWON = sidoArray.Item("GANGWON")
	if Not(isNull(sidoArray.Item("CHUNGCHEONGBUK"))) then result.sidoCount.CHUNGCHEONGBUK = sidoArray.Item("CHUNGCHEONGBUK")
	if Not(isNull(sidoArray.Item("DAEGU"))) then result.sidoCount.DAEGU = sidoArray.Item("DAEGU")
	if Not(isNull(sidoArray.Item("INCHEON"))) then result.sidoCount.INCHEON = sidoArray.Item("INCHEON")
	if Not(isNull(sidoArray.Item("GWANGJU"))) then result.sidoCount.GWANGJU = sidoArray.Item("GWANGJU")
	if Not(isNull(sidoArray.Item("JEJU"))) then result.sidoCount.JEJU = sidoArray.Item("JEJU")
	if Not(isNull(sidoArray.Item("DAEJEON"))) then result.sidoCount.DAEJEON = sidoArray.Item("DAEJEON")
	if Not(isNull(sidoArray.Item("ULSAN"))) then result.sidoCount.ULSAN = sidoArray.Item("ULSAN")
	if Not(isNull(sidoArray.Item("SEJONG"))) then result.sidoCount.SEJONG = sidoArray.Item("SEJONG")
	sidoArray.DisconnectObject()
	destroy sidoArray
end if

if Not(isNull(dic.Item("juso"))) then
	oleobject jusoList[]
	jusoList = dic.Item("juso")
	
	for i = 1 to upperbound(jusoList)
		result.juso[i].roadAddr1= string(jusoList[i].Item("roadAddr1"))
		result.juso[i].roadAddr2= string(jusoList[i].Item("roadAddr2"))
		result.juso[i].jibunAddr= string(jusoList[i].Item("jibunAddr"))
		result.juso[i].zipcode= string(jusoList[i].Item("zipcode"))
		result.juso[i].sectionNum= string(jusoList[i].Item("sectionNum"))
		
		if Not(isNull(jusoList[i].Item("detailBuildingName"))) then
			result.juso[i].detailBuildingName = jusoList[i].Item("detailBuildingName")
		end if
		
		if Not(isNull(jusoList[i].Item("relatedJibun"))) then
			result.juso[i].relatedJibun = jusoList[i].Item("relatedJibun")
		end if
	
		result.juso[i].dongCode= string(jusoList[i].Item("dongCode"))
		result.juso[i].streetCode= string(jusoList[i].Item("streetCode"))
	next
end if

return result
end function

function string urlencode (string target_string) 
OleObject wsh
Integer  li_rc
string ls_temp

wsh = CREATE OleObject
li_rc = wsh.ConnectToNewObject( "MSScriptControl.ScriptControl" )
wsh.language = "javascript"

ls_temp = wsh.Eval('encodeURI("'+target_string+'")')
return ls_temp
end function

on jusolink.create
call super::create
TriggerEvent( this, "constructor" )
end on

on jusolink.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on

event constructor;setnull(in_authority)
exception  = create jusolinkexception
scopes[1] = "200"
end event

