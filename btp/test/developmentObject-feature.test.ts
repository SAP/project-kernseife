import {
  calculateScoreAndLevel,
  determineNamespace,
  getDevelopmentObjectIdentifier,
  validateFindingsCsvColumns
} from '../srv/features/developmentObject-feature';
import { CleanCoreLevel } from '#cds-models/kernseife/enums';
import type {
  DevelopmentObject,
  FindingRecord,
  DevelopmentObjectFinding
} from '#cds-models/kernseife/db';
import {describe, expect, it} from '@jest/globals';

describe('developmentObject-feature', () => {
  describe('calculateScoreAndLevel', () => {
    it('should calculate score and level from finding list', () => {
      const ratingMap = new Map([
        ['BF9', { level: CleanCoreLevel.D, score: 10 }],
        ['BF5', { level: CleanCoreLevel.C, score: 5 }]
      ]);

      const findingList: DevelopmentObjectFinding[] = [
        {
          code: 'BF9',
          potentialCode: 'BF5',
          count: 2,
          total: 20
        } as DevelopmentObjectFinding
      ];

      const result = calculateScoreAndLevel(ratingMap, findingList);

      expect(result.score).toBe(20);
      expect(result.potentialScore).toBe(10);
      expect(result.level).toBe(CleanCoreLevel.D);
      expect(result.potentialLevel).toBe(CleanCoreLevel.C);
    });

    it('should handle multiple findings and return highest level', () => {
      const ratingMap = new Map([
        ['BF1', { level: CleanCoreLevel.B, score: 1 }],
        ['BF0', { level: CleanCoreLevel.A, score: 0 }]
      ]);

      const findingList: DevelopmentObjectFinding[] = [
        {
          code: 'BF1',
          potentialCode: 'BF0',
          count: 2,
          total: 2
        } as DevelopmentObjectFinding,
        {
          code: 'BF0',
          potentialCode: 'BF0',
          count: 1,
          total: 0
        } as DevelopmentObjectFinding
      ];

      const result = calculateScoreAndLevel(ratingMap, findingList);

      expect(result.level).toBe(CleanCoreLevel.B);
      expect(result.score).toBe(2);
    });

    it('should throw error when rating not found', () => {
      const ratingMap = new Map([]) as Map<
        string,
        {
          level: CleanCoreLevel;
          score: number;
        }
      >;
      const findingList: DevelopmentObjectFinding[] = [
        {
          code: 'MISSING',
          potentialCode: 'CODE2',
          count: 1,
          total: 10
        } as DevelopmentObjectFinding
      ];

      expect(() => calculateScoreAndLevel(ratingMap, findingList)).toThrow(
        'Rating Config missmatch'
      );
    });
  });

  describe('determineNamespace', () => {
    it('should return Z for Z namespace', () => {
      const devObj = { objectName: 'ZTEST' } as DevelopmentObject;
      expect(determineNamespace(devObj)).toBe('Z');
    });

    it('should return Y for Y namespace', () => {
      const devObj = { objectName: 'YTEST' } as DevelopmentObject;
      expect(determineNamespace(devObj)).toBe('Y');
    });

    it('should return forward slash namespace for custom namespace', () => {
      const devObj = { objectName: '/CUSTOM/TEST' } as DevelopmentObject;
      expect(determineNamespace(devObj)).toBe('/CUSTOM/');
    });

    it('should return undefined for standard namespace', () => {
      const devObj = { objectName: 'STDTEST' } as DevelopmentObject;
      expect(determineNamespace(devObj)).toBeUndefined();
    });
  });

  describe('getDevelopmentObjectIdentifier', () => {
    it('should concatenate all identifier parts', () => {
      const obj = {
        systemId: 'SYS1',
        devClass: 'DEVC',
        objectType: 'CLAS',
        objectName: 'TEST'
      } as FindingRecord;

      const result = getDevelopmentObjectIdentifier(obj);

      expect(result).toBe('SYS1DEVCCLASTEST');
    });

    it('should handle undefined values', () => {
      const obj = {
        systemId: 'SYS1',
        devClass: undefined,
        objectType: 'CLAS',
        objectName: 'TEST'
      } as unknown as FindingRecord;

      const result = getDevelopmentObjectIdentifier(obj);

      expect(result).toBe('SYS1CLASTEST');
    });
  });

  describe('validateFindingsCsvColumns', () => {
    it('should validate correct column headers', () => {
      const headers = ['runId', 'itemId', 'objectType', 'objectName', 'devClass', 'softwareComponent', 'messageId', 'refObjectType', 'refObjectName'];
      const result = validateFindingsCsvColumns(headers);

      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should return errors for missing required columns', () => {
      const headers = ['objectType', 'objectName']; // missing many required fields
      const result = validateFindingsCsvColumns(headers);

      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors.some(e => e.includes('runId'))).toBe(true);
      expect(result.errors.some(e => e.includes('itemId'))).toBe(true);
      expect(result.errors.some(e => e.includes('messageId'))).toBe(true);
    });

    it('should return all missing column errors at once', () => {
      const headers = ['someRandomColumn', 'anotherColumn'];
      const result = validateFindingsCsvColumns(headers);

      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBe(9); // All required fields missing
    });
  });
});
