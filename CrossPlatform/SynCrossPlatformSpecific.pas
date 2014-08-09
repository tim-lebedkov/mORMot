/// system-specific cross-platform units
// - this unit is a part of the freeware Synopse mORMot framework,
// licensed under a MPL/GPL/LGPL tri-license; version 1.18
unit SynCrossPlatformSpecific;

{
    This file is part of Synopse mORMot framework.

    Synopse mORMot framework. Copyright (C) 2014 Arnaud Bouchez
      Synopse Informatique - http://synopse.info

  *** BEGIN LICENSE BLOCK *****
  Version: MPL 1.1/GPL 2.0/LGPL 2.1

  The contents of this file are subject to the Mozilla Public License Version
  1.1 (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  for the specific language governing rights and limitations under the License.

  The Original Code is Synopse mORMot framework.

  The Initial Developer of the Original Code is Arnaud Bouchez.

  Portions created by the Initial Developer are Copyright (C) 2014
  the Initial Developer. All Rights Reserved.

  Contributor(s):
  - danielkuettner
  
  Alternatively, the contents of this file may be used under the terms of
  either the GNU General Public License Version 2 or later (the "GPL"), or
  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
  in which case the provisions of the GPL or the LGPL are applicable instead
  of those above. If you wish to allow use of your version of this file only
  under the terms of either the GPL or the LGPL, and not to allow others to
  use your version of this file under the terms of the MPL, indicate your
  decision by deleting the provisions above and replace them with the notice
  and other provisions required by the GPL or the LGPL. If you do not delete
  the provisions above, a recipient may use your version of this file under
  the terms of any one of the MPL, the GPL or the LGPL.

  ***** END LICENSE BLOCK *****

  
  Version 1.18
  - first public release, corresponding to mORMot Framework 1.18
  - each operating system will have its own API calls in this single unit
  - would compile with Delphi for any platform (including NextGen for mobiles),
    with FPC 2.7 or Kylix, and with SmartMobileStudio 2.1

}

{$ifdef DWSCRIPT} // always defined since SMS 1.1.2
  {$define ISDWS}           // e.g. for SmartMobileStudio or Delphi Web Script
  {$define ISSMS}           // for SmartMobileStudio
  {$define HASINLINE}
{$else}
  {$i SynCrossPlatform.inc} // define e.g. HASINLINE
  {$ifdef MSWINDOWS}
    {$ifdef FPC}
      {$define USEFCL}  // for debugging the FCL within Lazarus
    {$else}
    {$ifdef UNICODE}    // for debugging Indy within the IDE
      {$define USEINDY}
    {$else}
      {$define USESYNCRT}
    {$endif}
    {$endif}
  {$else}
    {$ifdef FPC}
      {$define USEFCL}
    {$else}
      {$define USEINDY}
    {$endif}
  {$endif}
{$endif}

interface

{$ifdef ISDWS}
uses
  SmartCL.System,
  System.Types,
  w3c.date;
{$else}
uses
  SysUtils,
  Classes;
{$endif}

type
  {$ifdef ISDWS}

  // HTTP body may not match the string type, and could be binary 
  THttpBody = string;

  // define some Delphi types not supported natively by DWS/SMS
  char = string;
  byte = integer;
  word = integer;
  cardinal = integer;
  Int64 = integer;
  currency = float;
  TPersistent = TObject;
  TObjectList = array of TObject;
  TStringList = array of string;
  TVariantDynArray = array of variant;
  TIntegerDynArray = array of integer;

  // as defined in SmartCL.Inet and expected by XMLHttpRequest
  THttpRequestReadyState = (rrsUnsent          = 0,
                            rrsOpened          = 1,
                            rrsHeadersReceived = 2,
                            rrsLoading         = 3,
                            rrsDone            = 4);
  {$else}

  /// will store input and output HTTP body content 
  // - HTTP body may not match the string type, and could be binary 
  // - this kind of variable is compatible with NextGen version of the compiler
  THttpBody = array of byte;

  {$ifdef NEXTGEN}
  /// see TUTF8Buffer = TBytes in SynCrossPlatformJSON
  AnsiChar = byte;
  {$endif NEXTGEN}

  {$endif ISDWS}

  /// used to store the request of a REST call
  TSQLRestURIParams = record
    /// input parameter containing the caller URI
    Url: string;
    /// input parameter containing the caller method
    {$ifdef ISDWS}&Method{$else}Method{$endif}: string;
    /// input parameter containing the caller message headers
    InHead: string;
    /// input parameter containing the caller message body
    InBody: THttpBody;
    /// output parameter to be set to the response message header
    OutHead: string;
    /// output parameter to be set to the response message body
    OutBody: THttpBody;
    /// output parameter to be set to the HTTP status integer code
    OutStatus: cardinal;
    /// output parameter to be set to the database internal state
    // - this is the only mORMot-specific parameter
    OutInternalState: cardinal;
    {$ifdef ISDWS}
    /// the associated TXMLHttpRequest instance
    XHR: THandle;
    /// callback events for asynchronous call
    // - will be affected to the corresponding XHR events
    OnSuccess: TProcedureRef;
    OnError: TProcedureRef;
    {$endif}
  end;

  /// the connection parameters, as stored and used by TAbstractHttpConnection
  TSQLRestConnectionParams = record
    /// the server name or IP address
    Server: string;
    /// the server port
    Port: integer;
    /// if the connection should be HTTPS
    Https: boolean;
    {$ifndef ISSMS}
    /// the optional proxy name to be used
    ProxyName: string;
    /// the optional proxy password to be used
    ProxyByPass: string;
    /// the timeout when sending data, in ms
    SendTimeout: cardinal;
    /// the timeout when receiving data, in ms
    ReceiveTimeout: cardinal
    {$endif}
  end;

  /// abstract class for HTTP client connection
  TAbstractHttpConnection = class
  protected
    fParameters: TSQLRestConnectionParams;
    fURL: string;
  public
    /// this is the main entry point for all HTTP clients
    // - connect to http://aServer:aPort or https://aServer:aPort
    // - optional aProxyName may contain the name of the proxy server to use,
    // and aProxyByPass an optional semicolon delimited list of host names or
    // IP addresses, or both, that should not be routed through the proxy
    constructor Create(const aParameters: TSQLRestConnectionParams); virtual;
    /// perform the request
    // - this is the main entry point of this class
    // - inherited classes should override this abstract method
    procedure URI(var Call: TSQLRestURIParams;
      const InDataType: string; KeepAlive: integer); virtual; abstract;

    /// the remote server full URI
    // - e.g. 'http://myserver:888/'
    property Server: string read fURL;
    /// the connection parameters
    property Parameters: TSQLRestConnectionParams read fParameters;
  end;

  /// define the inherited class for HTTP client connection
  TAbstractHttpConnectionClass = class of TAbstractHttpConnection;


const
  /// MIME content type used for JSON communication
  JSON_CONTENT_TYPE = 'application/json; charset=UTF-8';

  /// HTML Status Code for "Continue"
  HTML_CONTINUE = 100;
  /// HTML Status Code for "Switching Protocols"
  HTML_SWITCHINGPROTOCOLS = 101;
  /// HTML Status Code for "Success"
  HTML_SUCCESS = 200;
  /// HTML Status Code for "Created"
  HTML_CREATED = 201;
  /// HTML Status Code for "Accepted"
  HTML_ACCEPTED = 202;
  /// HTML Status Code for "Non-Authoritative Information"
  HTML_NONAUTHORIZEDINFO = 203;
  /// HTML Status Code for "No Content"
  HTML_NOCONTENT = 204;
  /// HTML Status Code for "Multiple Choices"
  HTML_MULTIPLECHOICES = 300;
  /// HTML Status Code for "Moved Permanently"
  HTML_MOVEDPERMANENTLY = 301;
  /// HTML Status Code for "Found"
  HTML_FOUND = 302;
  /// HTML Status Code for "See Other"
  HTML_SEEOTHER = 303;
  /// HTML Status Code for "Not Modified"
  HTML_NOTMODIFIED = 304;
  /// HTML Status Code for "Use Proxy"
  HTML_USEPROXY = 305;
  /// HTML Status Code for "Temporary Redirect"
  HTML_TEMPORARYREDIRECT = 307;
  /// HTML Status Code for "Bad Request"
  HTML_BADREQUEST = 400;
  /// HTML Status Code for "Unauthorized"
  HTML_UNAUTHORIZED = 401;
  /// HTML Status Code for "Forbidden"
  HTML_FORBIDDEN = 403;
  /// HTML Status Code for "Not Found"
  HTML_NOTFOUND = 404;
  // HTML Status Code for "Method Not Allowed"
  HTML_NOTALLOWED = 405;
  // HTML Status Code for "Not Acceptable"
  HTML_NOTACCEPTABLE = 406;
  // HTML Status Code for "Proxy Authentication Required"
  HTML_PROXYAUTHREQUIRED = 407;
  /// HTML Status Code for "Request Time-out"
  HTML_TIMEOUT = 408;
  /// HTML Status Code for "Internal Server Error"
  HTML_SERVERERROR = 500;
  /// HTML Status Code for "Not Implemented"
  HTML_NOTIMPLEMENTED = 501;
  /// HTML Status Code for "Bad Gateway"
  HTML_BADGATEWAY = 502;
  /// HTML Status Code for "Service Unavailable"
  HTML_UNAVAILABLE = 503;
  /// HTML Status Code for "Gateway Timeout"
  HTML_GATEWAYTIMEOUT = 504;
  /// HTML Status Code for "HTTP Version Not Supported"
  HTML_HTTPVERSIONNONSUPPORTED = 505;


/// gives access to the class type to implement a HTTP connection
// - will use WinHTTP API (from our SynCrtSock) under Windows
// - will use Indy for Delphi on other platforms
// - will use fcl-web (fphttpclient) with FreePascal
function HttpConnectionClass: TAbstractHttpConnectionClass;

  
/// convert a text into UTF-8 binary buffer
function TextToHttpBody(const Text: string): THttpBody;

/// convert a UTF-8 binary buffer into texts
procedure HttpBodyToText(const Body: THttpBody; var Text: string);


{$ifdef ISDWS}

procedure DoubleQuoteStr(var text: string);
function IdemPropName(const PropName1,PropName2: string): boolean;
function StartWithPropName(const PropName1,PropName2: string): boolean;
function VarRecToValue(const VarRec: variant; var tmpIsString: boolean): string;
procedure DecodeTime(Value: TDateTime; var HH,MM,SS,MS: word);
procedure DecodeDate(Value: TDateTime; var Y,M,D: word);
function TryEncodeDate(Y,M,D: integer; var Value: TDateTime): boolean;
function TryEncodeTime(HH,MM,SS,MS: integer; var Value: TDateTIme): boolean;
function NowToIso8601: string;
function DateTimeToIso8601(Value: TDateTime): string;
function Iso8601ToDateTime(const Value: string): TDateTime;
function TryStrToInt(const S: string; var Value: integer): Boolean;
function TryStrToInt64(const S: string; var Value: Int64): Boolean;
function UpCase(ch: Char): Char; inline;
function GetNextCSV(const str: string; var index: Integer; var res: string;
  Sep: char): boolean;

type
  /// which kind of document the TJSONVariantData contains
  TJSONVariantKind = (jvUndefined, jvObject, jvArray);

  /// stores any JSON object or array as variant
  TJSONVariantData = class
  public
    Kind: TJSONVariantKind;
    Names: TStrArray;
    Values: TVariantDynArray;
    /// initialize the low-level memory structure with a given JSON content
    constructor Create(const aJSON: string);
    /// initialize the low-level memory structure with a given object
    constructor CreateFrom(const document: variant);
    /// number of items in this jvObject or jvArray
    property Count: integer read (Values.Count);
  end;

/// guess the type of a supplied variant
function VariantType(const Value: variant): TJSONVariantKind;

{$endif}


implementation

{$ifdef USEFCL}
uses
  fphttpclient;
{$endif}

{$ifdef USEINDY}
uses
  IdHTTP, IdCoderMIME, IdSSLOpenSSL;
{$endif}

{$ifdef USESYNCRT}
uses
  Windows,
  SynCrtSock;
{$endif}


function TextToHttpBody(const Text: string): THttpBody;
{$ifdef ISSMS}
begin
  // http://ecmanaut.blogspot.fr/2006/07/encoding-decoding-utf8-in-javascript.html
  asm
    @result=unescape(encodeURIComponent(@Text));
  end;
end;
{$else}
{$ifdef NEXTGEN}
begin
  result := THttpBody(TEncoding.UTF8.GetBytes(Text));
end;
{$else}
var utf8: UTF8String;
    n: integer;
begin
  utf8 := UTF8Encode(Text);
  n := length(utf8);
  SetLength(result,n);
  move(pointer(utf8)^,pointer(result)^,n);
end;
{$endif}
{$endif}

procedure HttpBodyToText(const Body: THttpBody; var Text: string);
{$ifdef ISSMS}
begin
  asm
    @Text=decodeURIComponent(escape(@Body));
  end;
end;
{$else}
{$ifdef NEXTGEN}
begin
  Text := TEncoding.UTF8.GetString(TBytes(Body));
end;
{$else}
var utf8: UTF8String;
    L: integer;
begin
  L := length(Body);
  SetLength(utf8,L);
  move(pointer(Body)^,pointer(utf8)^,L);
  {$ifdef UNICODE}
  Text := UTF8ToString(utf8);
  {$else}
  Text := UTF8Decode(utf8);
  {$endif}
end;
{$endif}
{$endif}


{ TAbstractHttpConnection }

const
  INTERNET_DEFAULT_HTTP_PORT = 80;
  INTERNET_DEFAULT_HTTPS_PORT = 443; 

constructor TAbstractHttpConnection.Create(
  const aParameters: TSQLRestConnectionParams);
begin
  inherited Create;
  fParameters := aParameters;
  if fParameters.Port=0 then
    if fParameters.Https then
      fParameters.Port := INTERNET_DEFAULT_HTTPS_PORT else
      fParameters.Port := INTERNET_DEFAULT_HTTP_PORT;
  if fParameters.Https then
    fURL := 'https://' else
    fURL := 'http://';
  fURL := fURL+fParameters.Server+':'+IntToStr(fParameters.Port)+'/';
end;


{$ifdef USEFCL}

type
  TFclHttpConnectionClass = class(TAbstractHttpConnection)
  protected
    fConnection: TFPHttpClient;
  public
    constructor Create(const aParameters: TSQLRestConnectionParams); override;
    procedure URI(var Call: TSQLRestURIParams; const InDataType: string;
      KeepAlive: integer); override;
    destructor Destroy; override;
  end;

{ TFclHttpConnectionClass }

constructor TFclHttpConnectionClass.Create(
  const aParameters: TSQLRestConnectionParams);
begin
  inherited Create(aParameters);
  fConnection := TFPHttpClient.Create(nil);
end;

procedure TFclHttpConnectionClass.URI(var Call: TSQLRestURIParams;
  const InDataType: string; KeepAlive: integer);
var InStr,OutStr: TBytesStream;
begin
  InStr := TBytesStream.Create(Call.InBody);
  OutStr := TBytesStream.Create;
  try
    fConnection.RequestHeaders.Text := Call.InHead;
    fConnection.RequestBody := InStr;
    fConnection.HTTPMethod(Call.Method,fURL+Call.Url,OutStr,[]);
    Call.OutStatus := fConnection.ResponseStatusCode;
    Call.OutHead := fConnection.ResponseHeaders.Text;
    Call.OutBody := OutStr.Bytes;
    SetLength(Call.OutBody,OutStr.Position);
  finally
    OutStr.Free;
    InStr.Free;
  end;
end;

destructor TFclHttpConnectionClass.Destroy;
begin
  fConnection.Free;
  inherited Destroy;
end;

function HttpConnectionClass: TAbstractHttpConnectionClass;
begin
  result := TFclHttpConnectionClass;
end;

{$endif}

{$ifdef USEINDY}

type
  TIndyHttpConnectionClass = class(TAbstractHttpConnection)
  protected
    fConnection: TIdHTTP;
  public
    constructor Create(const aParameters: TSQLRestConnectionParams); override;
    procedure URI(var Call: TSQLRestURIParams; const InDataType: string;
      KeepAlive: integer); override;
    destructor Destroy; override;
  end;

{ TIndyHttpConnectionClass }

constructor TIndyHttpConnectionClass.Create(
  const aParameters: TSQLRestConnectionParams);
begin
  inherited;
  fConnection := TIdHTTP.Create(nil);
  if fParameters.Https then
    fConnection.IOHandler:= TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  if fParameters.ProxyName<>'' then
    fConnection.ProxyParams.ProxyServer := fParameters.ProxyName;
end;

destructor TIndyHttpConnectionClass.Destroy;
begin
  fConnection.Free;
  inherited;
end;

procedure TIndyHttpConnectionClass.URI(var Call: TSQLRestURIParams;
  const InDataType: string; KeepAlive: integer);
var InStr, OutStr: TStream;
    OutLen,i: integer;
    Auth: string;
begin
  InStr := TMemoryStream.Create;
  OutStr := TMemoryStream.Create;
  try
    fConnection.Request.RawHeaders.Text := Call.InHead;
    Auth := fConnection.Request.RawHeaders.Values['Authorization'];
    if (Auth<>'') and SameText(Copy(Auth,1,6),'Basic ') then begin
      // see http://synopse.info/forum/viewtopic.php?pid=11761#p11761
      with TIdDecoderMIME.Create do
      try
        Auth := DecodeString(copy(Auth,7,maxInt));
      finally
        Free;
      end;
      i := Pos(':',Auth);
      if i>0 then begin
        fConnection.Request.BasicAuthentication := true;
        fConnection.Request.Username := copy(Auth,1,i-1);
        fConnection.Request.Password := Copy(Auth,i+1,maxInt);
      end;
    end;
    if Call.InBody<>nil then begin
      InStr.Write(Call.InBody[0],length(Call.InBody));
      InStr.Seek(0,soBeginning);
      fConnection.Request.Source := InStr;
    end;
    if Call.Method='GET' then // allow 404 as valid Call.OutStatus
      fConnection.Get(fURL+Call.Url,OutStr,[HTML_SUCCESS,HTML_NOTFOUND]) else
    if Call.Method='POST' then
      fConnection.Post(fURL+Call.Url,InStr,OutStr) else
    if Call.Method='PUT' then
      fConnection.Put(fURL+Call.Url,InStr) else
    if Call.Method='DELETE' then
      fConnection.Delete(fURL+Call.Url) else
      raise Exception.CreateFmt('Indy does not know method %s',[Call.Method]);
    Call.OutStatus := fConnection.Response.ResponseCode;
    Call.OutHead := fConnection.Response.RawHeaders.Text;
    OutLen := OutStr.Size;
    if OutLen>0 then begin
      SetLength(Call.OutBody,OutLen);
      OutStr.Seek(0,soBeginning);
      OutStr.Read(Call.OutBody[0],OutLen);
    end;
  finally
    OutStr.Free;
    InStr.Free;
  end;
end;

function HttpConnectionClass: TAbstractHttpConnectionClass;
begin
  result := TIndyHttpConnectionClass;
end;


{$endif}

{$ifdef USESYNCRT}

type
  TWinHttpConnectionClass = class(TAbstractHttpConnection)
  protected
    fConnection: TWinHttpAPI;
    fLock: TRTLCriticalSection;
  public
    constructor Create(const aParameters: TSQLRestConnectionParams); override;
    procedure URI(var Call: TSQLRestURIParams; const InDataType: string;
      KeepAlive: integer); override;
    destructor Destroy; override;
  end;

{ TWinHttpConnectionClass }

constructor TWinHttpConnectionClass.Create(
  const aParameters: TSQLRestConnectionParams);
begin
  inherited;
  InitializeCriticalSection(fLock);
  fConnection := TWinHTTP.Create(RawByteString(fParameters.Server),
    RawByteString(IntToStr(fParameters.Port)),fParameters.Https,
    RawByteString(fParameters.ProxyName),RawByteString(fParameters.ProxyByPass),
    fParameters.SendTimeout,fParameters.ReceiveTimeout);
end;

destructor TWinHttpConnectionClass.Destroy;
begin
  fConnection.Free;
  DeleteCriticalSection(fLock);
  inherited;
end;

procedure TWinHttpConnectionClass.URI(var Call: TSQLRestURIParams;
  const InDataType: string; KeepAlive: integer);
var inb,outb,outh: RawByteString;
    n: integer;
begin
  EnterCriticalSection(fLock);
  try
    SetString(inb,PAnsiChar(Call.InBody),length(Call.InBody));
    Call.OutStatus := fConnection.Request(RawByteString(Call.Url),
      RawByteString(Call.Method),KeepAlive,RawByteString(Call.InHead),
      inb,RawByteString(InDataType),outh,outb);
    Call.OutHead := string(outh);
    n := length(outb);
    SetLength(Call.OutBody,n);
    Move(pointer(outb)^,pointer(Call.OutBody)^,n);
  finally
    LeaveCriticalSection(fLock);
  end;
end;

function HttpConnectionClass: TAbstractHttpConnectionClass;
begin
  result := TWinHttpConnectionClass;
end;

{$endif}


{$ifdef ISDWS}

procedure DoubleQuoteStr(var text: string);
var i,j: integer;
    tmp: string;
begin
  i := pos('"',text);
  if i=0 then begin
    text := '"'+text+'"';
    exit;
  end;
  tmp := '"'+copy(text,1,i)+'"';
  for j := i+1 to length(text) do
    if text[j]='"' then
      tmp := tmp+'""' else
      tmp := tmp+text[j];
  text := tmp+'"';
end;

function IdemPropName(const PropName1,PropName2: string): boolean;
begin
  result := uppercase(PropName1)=uppercase(PropName2);
end;

function StartWithPropName(const PropName1,PropName2: string): boolean;
var L: integer;
begin
  L := length(PropName2);
  if length(PropName1)<L then
    result := false else
    result := IdemPropName(copy(PropName1,1,L),PropName2);
end;

function VarRecToValue(const VarRec: variant; var tmpIsString: boolean): string;
begin
  tmpIsString := TVariant.IsString(VarRec);
  if TVariant.IsNull(VarRec) then
    result := 'null' else
    result := TVariant.AsString(VarRec);
end;

procedure DecodeTime(Value: TDateTime; var HH,MM,SS,MS: word);
var date := new JDate;
begin
  date.AsDateTime := Value;
  HH := date.getUTCHours;
  MM := date.getUTCMinutes;
  SS := date.getUTCSeconds;
end;

procedure DecodeDate(Value: TDateTime; var Y,M,D: word);
var date := new JDate;
begin
  date.AsDateTime := Value;
  Y := date.getUTCFullYear;
  M := date.getUTCMonth+1;
  D := date.getUTCDate;
end;

function TryEncodeDate(Y,M,D: integer; var Value: TDateTime): boolean;
begin
  try
    Value := EncodeDate(Y,M,D);
    result := true
  except
    result := false;
  end;
end;

function TryEncodeTime(HH,MM,SS,MS: integer; var Value: TDateTime): boolean;
begin
  try
    Value := EncodeTime(HH,MM,SS,MS);
    result := true
  except
    result := false;
  end;
end;

function UpCase(ch: Char): Char; inline;
begin
  result := ch.UpperCase;
end;

function GetNextCSV(const str: string; var index: Integer; var res: string;
  Sep: char): boolean;
var i,L: integer;
begin
  L := length(str);
  if index<=L then begin
    i := index;
    while i<=L do
      if str[i]=Sep then
        break else
        inc(i);
    res := copy(str,index,i-index);
    index := i+1;
    result := true;
  end else
    result := false;
end;

function TryStrToInt(const S: string; var Value: Integer): Boolean;
begin
  try
    Value := StrToInt(S);
    result := true;
  except
    on E: Exception do
      result := false;
  end;
end;

function TryStrToInt64(const S: string; var Value: Int64): Boolean; inline;
begin
  result := TryStrToInt(S,Value);
end;

function NowToIso8601: string;
begin
  result := DateTimeToIso8601(Now);
end;

function DateTimeToIso8601(Value: TDateTime): string;
begin // e.g. YYYY-MM-DD Thh:mm:ss or YYYY-MM-DDThh:mm:ss
  if Value<=0 then
    result := '' else
  if frac(Value)=0 then
    result := FormatDateTime('yyyy-mm-dd',Value) else
  if trunc(Value)=0 then
    result := FormatDateTime('Thh:nn:ss',Value) else
    result := FormatDateTime('yyyy-mm-ddThh:nn:ss',Value);
end;

function Iso8601ToDateTime(const Value: string): TDateTime;
var Y,M,D, HH,MI,SS: cardinal;
begin //  YYYY-MM-DD   Thh:mm:ss  or  YYYY-MM-DDThh:mm:ss
      //  1234567890   123456789      1234567890123456789
  result := 0;
  case Length(Value) of
  9: if (Value[1]='T') and (Value[4]=':') and (Value[7]=':') then begin
    HH := ord(Value[2])*10+ord(Value[3])-(48+480);
    MI := ord(Value[5])*10+ord(Value[6])-(48+480);
    SS := ord(Value[8])*10+ord(Value[9])-(48+480);
    TryEncodeTime(HH,MI,SS,0,result);
  end;
  10: if (Value[5]=Value[8]) and (ord(Value[8]) in [ord('-'),ord('/')]) then begin
    Y := ord(Value[1])*1000+ord(Value[2])*100+
         ord(Value[3])*10+ord(Value[4])-(48+480+4800+48000);
    M := ord(Value[6])*10+ord(Value[7])-(48+480);
    D := ord(Value[9])*10+ord(Value[10])-(48+480);
    TryEncodeDate(Y,M,D,result);
  end;
  19: if (Value[5]=Value[8]) and (ord(Value[8]) in [ord('-'),ord('/')]) and
         (ord(Value[11]) in [ord(' '),ord('T')]) and (Value[14]=':') and (Value[17]=':') then begin
    Y := ord(Value[1])*1000+ord(Value[2])*100+
         ord(Value[3])*10+ord(Value[4])-(48+480+4800+48000);
    M := ord(Value[6])*10+ord(Value[7])-(48+480);
    D := ord(Value[9])*10+ord(Value[10])-(48+480);
    HH := ord(Value[12])*10+ord(Value[13])-(48+480);
    MI := ord(Value[15])*10+ord(Value[16])-(48+480);
    SS := ord(Value[18])*10+ord(Value[19])-(48+480);
    if (Y<=9999) and ((M-1)<12) and ((D-1)<31) and
       (HH<24) and (MI<60) and (SS<60) then
      result := EncodeDate(Y,M,D)+EncodeTime(HH,MI,SS,0);
  end;
  end;
end;


{ TJSONVariantData }

{$HINTS OFF}
function VariantType(const Value: variant): TJSONVariantKind;
begin
  asm
    if (@Value === null) return 0;
    if (typeof(@Value) !== "object") return 0;
    if (Object.prototype.toString.call(@Value) === "[object Array]") return 2;
    return 1;
  end;
end;
{$HINTS ON}

constructor TJSONVariantData.Create(const aJSON: string);
begin
  CreateFrom(JSON.Parse(aJSON));
end;

constructor TJSONVariantData.CreateFrom(const document: Variant);
var name: string;
begin
  Kind := VariantType(document);
  case Kind of
  jvObject: begin
    Names := TVariant.Properties(document);
    for name in Names do
      Values.Add(document[name]);
  end;
  jvArray: asm
    @Values=@document;
  end;
  end;
end;


type
  TSMSHttpConnectionClass = class(TAbstractHttpConnection)
  protected  // see http://www.w3.org/TR/XMLHttpRequest
  public
    procedure URI(var Call: TSQLRestURIParams; const InDataType: string;
      KeepAlive: integer); override;
  end;

{ TSMSHttpConnectionClass }

procedure TSMSHttpConnectionClass.URI(var Call: TSQLRestURIParams;
  const InDataType: string; KeepAlive: integer);
begin
  asm
    @Call.XHR = new XMLHttpRequest();
  end;
  if Assigned(Call.OnSuccess) then begin // asynchronous call
    Call.XHR.onreadystatechange := lambda
      if Call.XHR.readyState=rrsDone then begin
        Call.XHR.onreadystatechange := nil; // avoid any further trigger
        Call.OutStatus := Call.XHR.status;
        Call.OutHead := Call.XHR.getAllResponseHeaders();
        Call.OutBody := Call.XHR.responseText;
        Call.OnSuccess;
      end;
    end;
    Call.XHR.onerror := Call.OnError;
    Call.XHR.open(Call.Method,fURL+Call.Url,true);  // true for asynch call
  end else
    Call.XHR.open(Call.Method,fURL+Call.Url,false); // false for synch call
  if Call.InHead<>'' then begin
    var i = 1;
    var line: string;
    while GetNextCSV(Call.InHead,i,line,#10) do begin
      var l := pos(':',line );
      if l=0 then
        continue;
      var head := trim(copy(line,1,l-1));
      var value := trim(copy(line,l+1,length(line)));
      if (head<>'') and (value<>'') then
        Call.XHR.setRequestHeader(head,value);
    end;
  end;
  if Call.InBody='' then
    Call.XHR.send(null) else
    Call.XHR.send(Call.InBody);
  if not Assigned(Call.OnSuccess) then begin // synchronous call
    Call.OutStatus := Call.XHR.status;
    Call.OutHead := Call.XHR.getAllResponseHeaders();
    Call.OutBody := Call.XHR.responseText;
  end;
end;


function HttpConnectionClass: TAbstractHttpConnectionClass;
begin
  result := TSMSHttpConnectionClass;
end;


procedure TestSMS;
var doc: TJSONVariantData;
begin
  assert(VariantType(123)=jvUndefined);
  assert(VariantType(null)=jvUndefined);
  assert(VariantType(TVariant.CreateObject)=jvObject);
  assert(VariantType(TVariant.CreateArray)=jvArray);
  doc := TJSONVariantData.Create('{"a":1,"b":"B"}');
  assert(doc.Kind=jvObject);
  assert(doc.Count=2);
  assert(doc.Names[0]='a');
  assert(doc.Names[1]='b');
  assert(doc.Values[0]=1);
  assert(doc.Values[1]='B');
  doc := TJSONVariantData.Create('["a",2]');
  assert(doc.Kind=jvArray);
  assert(doc.Count=2);
  assert(doc.Names.Count=0);
  assert(doc.Values[0]='a');
  assert(doc.Values[1]=2);
end;


initialization
  TestSMS;

{$endif ISDWS}
end.
