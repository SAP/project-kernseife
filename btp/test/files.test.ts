import { describe, expect, it } from '@jest/globals';
import { isZipFile } from '../srv/lib/files';

describe('isZipFile', () => {
  it.each([
    'application/zip',
    'application/x-zip-compressed',
    'application/x-zip',
    'application/x-compressed',
    'multipart/x-zip'
  ])('accepts %s', (mimeType) => {
    expect(isZipFile(mimeType)).toBe(true);
  });

  it('rejects a non-ZIP MIME type', () => {
    expect(isZipFile('application/json')).toBe(false);
  });
});
