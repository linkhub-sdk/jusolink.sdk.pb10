$PBExportHeader$jusolinkexception.sru
forward
global type jusolinkexception from exception
end type
end forward

global type jusolinkexception from exception
end type
global jusolinkexception jusolinkexception

type variables
long in_code
end variables

forward prototypes
public function long getcode ()
public subroutine setcode (long code)
public function jusolinkexception setcodenmessage (long code, string new_message)
end prototypes

public function long getcode ();return in_code
end function

public subroutine setcode (long code);in_code = code
end subroutine

public function jusolinkexception setcodenmessage (long code, string new_message);in_code = code
setMessage(new_message)
return this
end function

on jusolinkexception.create
call super::create
TriggerEvent( this, "constructor" )
end on

on jusolinkexception.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on

