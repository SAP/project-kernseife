@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: User Name'
define view entity ZKNSF_I_USER_NAME
  as select from I_User as user
  left outer join I_AddressPersonName as addr on addr.AddressPersonID = user.AddressPersonID and addr.AddressRepresentationCode = ''
{
  key user.UserID                                  as userId,
      addr.PersonFullName as userName
}
