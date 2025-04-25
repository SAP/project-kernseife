export type ClassificationImport = {
  tadirObjectType: string;
  tadirObjectName: string;
  objectType: string;
  objectName: string;
  applicationComponent: string;
  adoptionEffort: string;
  softwareComponent: string;
  subType: string;
  comment: string;
  numberOfSimplificationNotes: number;
  noteList: {
    note: string;
    noteClassification_code: string;
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

export type ClassificationKey = {
    tadirObjectType: string;
    tadirObjectName: string;
    objectType: string;
    objectName: string;
}