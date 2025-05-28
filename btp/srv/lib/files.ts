import { PassThrough } from "node:stream";

export const streamToBuffer = async (stream: PassThrough): Promise<Buffer> => {
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
