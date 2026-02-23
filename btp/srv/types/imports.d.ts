export type ClassificationKey = {
  tadirObjectType: string;
  tadirObjectName: string;
  objectType: string;
  objectName: string;
};

export type ClassificationExternal = ClassificationKey & {
  applicationComponent: string;
  adoptionEffort: string;
  softwareComponent: string;
  subType: string;
  comment: string;
  numberOfSimplificationNotes: number;
  noteList: {
    note: string;
    noteClassification: string;
    title: string;
  }[];
  successorClassification?: string;
  codeSnippetList?: any[];
  successorList: {
    tadirObjectType: string;
    tadirObjectName: string;
    objectType: string;
    objectName: string;
    successorType?: string;
  }[];
  rating: string;
};

export type ClassificationImportLog = ClassificationKey & {
  oldRating?: string;
  newRating?: string;
  oldSuccessorClassification?: string;
  newSuccessorClassification?: string;
  status: 'NEW' | 'CONFLICT' | 'UPDATED' | 'UNCHANGED';
};

export type EnhancementImport = ClassificationKey & {
  applicationComponent: string;
  softwareComponent: string;
  internalUse: boolean;
  singleUse: boolean;
};

export type ExplicitImport = ClassificationKey & {
  applicationComponent: string;
  softwareComponent: string;
  internalUse: boolean;
  singleUse: boolean;
};

export type ProjectImport = {
  projectId: string;
  description: string;
  runId: string;
  systemId: string;
  status: string;
  statusDescription: string;
  statusCriticality: number;
  runSeries: string;
  runSeriesReferences: string;
  totalObjectCount: number;
  findingCount: number;
  _runState?: RunStateImport;
};

export interface RunStateImport {
  projectId: string;
  runSeries: string;
  projectStatus: string;
  runState: string;
  runStateText: string;
  startedOn: string;
  startedBy: string;
  total: number;
  failed: number;
  processed: number;
  criticalIndicator: number;
}

export type DevelopmentObjectImport = {
  projectId: string;
  runId: string;
  objectType: string;
  objectName: string;
  subType: string;
  devClass: string;
  softwareComponent: string;
  languageVersion: string;
  contactPerson: string;
  _findings: FindingImport[];
  _metrics: MetricsImport;
  _usages: UsageImport[];
};

export type FindingImport = {
  projectId: string;
  runId: string;
  itemId: string;
  objectType: string;
  objectName: string;
  devClass: string;
  softwareComponent: string;
  messageId: string;
  checksumVersion: number;
  checksumValue: number;
  refObjectType: string;
  refObjectName: string;
  refApplicationComponent: string;
  refSoftwareComponent: string;
  refDevClass: string;
};

export type MetricsImport = {
  projectId: string;
  objectType: string;
  objectName: string;
  difficulty: number;
  numberOfChanges: number;
};

export type UsageImport = {
  entry_point_type: string;
  entry_point_name: string;
  obj_type: string;
  obj_name: string;
  counter: number;
  last_used: string;
};

export type MissingClassificationImport = ClassificationKey & {
  subType: string;
  applicationComponent: string;
  softwareComponent: string;
};
