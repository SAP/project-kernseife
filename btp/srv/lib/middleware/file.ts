import { PassThrough } from 'node:stream';

export const readFile = async (file: any) : Promise<Buffer> => {
  const stream = new PassThrough();
  const buffers = [] as any[];
  file.pipe(stream);
  return await new Promise((resolve) => {
    stream.on('data', (dataChunk: any) => {
      buffers.push(dataChunk);
    });
    stream.on('end', async () => {
      const buffer = Buffer.concat(buffers);
      resolve(buffer);
    });
  });
};
