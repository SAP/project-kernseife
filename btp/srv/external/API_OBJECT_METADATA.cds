/* checksum : 15d8f3aded263a5ace6d93916efccc49 */
@cds.external                              : true
@Capabilities.FilterFunctions              : [
  'eq',
  'ne',
  'gt',
  'ge',
  'lt',
  'le',
  'and',
  'or',
  'contains',
  'startswith',
  'endswith',
  'any',
  'all'
]
@Capabilities.SupportedFormats             : [
  'application/json',
  'application/pdf'
]
@PDF.Features                              : {
  DocumentDescriptionReference : '../../../../default/iwbep/common/0001/$metadata',
  DocumentDescriptionCollection: 'MyDocumentDescriptions',
  ArchiveFormat                : true,
  Border                       : true,
  CoverPage                    : true,
  FitToPage                    : true,
  FontName                     : true,
  FontSize                     : true,
  Margin                       : true,
  Padding                      : true,
  Signature                    : true,
  HeaderFooter                 : true,
  ResultSizeDefault            : 20000,
  ResultSizeMaximum            : 20000
}
@Capabilities.KeyAsSegmentSupported        : true
@Capabilities.AsynchronousRequestsSupported: true
service API_OBJECT_METADATA {};

@cds.external                                                : true
@cds.persistence.skip                                        : true
@Common.Label                                                : 'Kernseife: Retrieve Object Metadata'
@Capabilities.SearchRestrictions.Searchable                  : false
@Capabilities.InsertRestrictions.Insertable                  : false
@Capabilities.DeleteRestrictions.Deletable                   : false
@Capabilities.UpdateRestrictions.Updatable                   : false
@Capabilities.UpdateRestrictions.QueryOptions.SelectSupported: true
entity API_OBJECT_METADATA.objectMetadata {
      @Common.IsUpperCase: true
      @Common.Label      : 'Object Type'
      @Common.Heading    : 'Obj.'
  key objectType           : String(4) not null;

      @Common.IsUpperCase: true
      @Common.Label      : 'Object Name'
      @Common.QuickInfo  : 'Object Name in Object Directory'
  key objectName           : String(40) not null;

      @Common.IsUpperCase: true
      @Common.Label      : 'Software Component'
      softwareComponent    : String(30) not null;

      @Common.IsUpperCase: true
      @Common.Label      : 'Component ID'
      @Common.Heading    : 'Component'
      @Common.QuickInfo  : 'Application component ID'
      applicationComponent : String(24) not null;

      @Common.IsUpperCase: true
      @Common.Label      : 'Package'
      devClass             : String(30) not null;

      @Common.IsUpperCase: true
      @Common.Label      : 'subType'
      subType              : String(80) not null;
};
