import { afterAll, describe, expect, it, jest } from '@jest/globals';
import cds from '@sap/cds';
import { authenticatedUserAuth } from './utils/helpers';
import startTestServer from './utils/startTestServer';

const cdstest = startTestServer();
const { axios } = cdstest;

axios.defaults.auth = authenticatedUserAuth;
axios.defaults.timeout = 30000;
jest.setTimeout(30 * 1000);

describe('Testing Admin Service', () => {
  afterAll(async () => {
    await cdstest.data.reset();
  });

  it('AdminService - exists', async () => {
    const { AdminService } = cds.services;
    expect(AdminService).toBeDefined();
  });
});
