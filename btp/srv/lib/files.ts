import { PassThrough } from 'node:stream';

export const fileToBuffer = async (file: any): Promise<Buffer> => {
  const stream = new PassThrough();
  file.pipe(stream);
  return new Promise((resolve) => {
    const buffers: Buffer[] = [];
    stream.on('data', (dataChunk: Buffer) => {
      buffers.push(dataChunk);
    });
    stream.on('end', () => {
      resolve(Buffer.concat(buffers));
    });
  });
};
