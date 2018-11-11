unit Craft.Auth;

interface

function get_access_token(token: PAnsiChar; len: Integer; username, identity_token: PAnsiChar): Boolean;

implementation

function get_access_token(token: PAnsiChar; len: Integer; username, identity_token: PAnsiChar): Boolean;
begin
{

  If you want to log on Michael's server, use the original client !

  https://www.michaelfogleman.com/projects/craft/

}
  Result := False;
end;

end.
