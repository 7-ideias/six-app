import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  CUSTOMER_SIGNUP_DICTIONARY,
  CustomerSignupHttpError,
  CustomerSignupValidationError,
  buildCustomerSignupPayload,
  customerSignupErrorKey,
  extractCustomerSignupLink,
  normalizeCustomerSignupCompany,
  normalizeCustomerSignupValidationResponse,
} from '../../web/site-assets/js/customer-signup-core.mjs';
import { assertPublicDictionaryParity } from '../../web/site-assets/js/public-locale.mjs';

const token = 'abcdefghijklmnopqrstuvwx12345678';
const companyId = 'empresa-publica-123456';

test('normaliza link publico de auto-cadastro mantendo ids opacos', () => {
  const link = extractCustomerSignupLink(
    `?token=${token}&idUnicoDaEmpresa=${companyId}&tipo=PJ&doc=12345678000199`,
  );

  assert.equal(link.token, token);
  assert.equal(link.companyId, companyId);
  assert.equal(link.tipoPessoa, 'PJ');
  assert.equal(link.documento, '12345678000199');
});

test('normaliza identidade da empresa retornada pelo backend', () => {
  const company = normalizeCustomerSignupCompany({
    nomeEmpresa: 'Oficina Central LTDA',
    nomeFantasia: 'Oficina Central',
    telefone: '(47) 3333-0000',
    whatsapp: '(47) 99999-0000',
    email: 'contato@oficinacentral.com',
    site: 'https://oficinacentral.com',
    endereco: 'Rua Alfa, 120',
    logoBase64: 'abc123',
  });

  assert.equal(company.displayName, 'Oficina Central');
  assert.equal(company.legalName, 'Oficina Central LTDA');
  assert.equal(company.logoBase64, 'data:image/jpeg;base64,abc123');
});

test('resposta de validacao preserva metadados e empresa opcional', () => {
  const response = normalizeCustomerSignupValidationResponse({
    status: 'SUCCESS',
    code: 'AUTO_CUSTOMER_TOKEN_VALID',
    message: 'Token de auto-cadastro válido.',
    empresa: {
      nomeEmpresa: 'Empresa Teste',
      nomeFantasia: 'Loja Teste',
      telefone: '4730000000',
    },
    cliente: {
      tipoCadastro: 'COMPLETO',
      tipoPessoa: 'PJ',
      documento: '12345678000199',
      nome: 'Cliente Atual',
      telefone: '47999999999',
      email: 'cliente@teste.com',
      cep: '89000-000',
      logradouro: 'Rua A',
      numero: '15',
      complemento: 'Sala 3',
      bairro: 'Centro',
      cidade: 'Blumenau',
      uf: 'sc',
      observacoes: 'Receber por WhatsApp',
    },
  });

  assert.equal(response.code, 'AUTO_CUSTOMER_TOKEN_VALID');
  assert.equal(response.company.displayName, 'Loja Teste');
  assert.equal(response.company.phone, '4730000000');
  assert.equal(response.customer.documento, '12345678000199');
  assert.equal(response.customer.uf, 'SC');
  assert.equal(response.customer.tipoCadastro, 'COMPLETO');
});

test('payload publico mantem contrato tecnico e endereco consolidado', () => {
  const payload = buildCustomerSignupPayload(
    {
      tipoCadastro: 'COMPLETO',
      tipoPessoa: 'PF',
      nome: 'Maria',
      documento: '12345678900',
      telefone: '47999999999',
      email: 'maria@example.com',
      cep: '89000-000',
      logradouro: 'Rua A',
      numero: '12',
      complemento: 'Sala 2',
      bairro: 'Centro',
      cidade: 'Blumenau',
      uf: 'sc',
      observacoes: 'Preferir WhatsApp',
      consentimento: true,
    },
    { companyId, token },
  );

  assert.equal(payload.idUnicoDaEmpresa, companyId);
  assert.equal(payload.token, token);
  assert.equal(payload.documentoOriginal, '12345678900');
  assert.equal(payload.uf, 'SC');
  assert.equal(
    payload.enderecoCompleto,
    'Rua A, 12, Sala 2, Centro, Blumenau, SC, 89000-000',
  );
});

test('mapeamento de erros continua estavel', () => {
  assert.equal(
    customerSignupErrorKey(new CustomerSignupValidationError('required')),
    'error.required',
  );
  assert.equal(
    customerSignupErrorKey(new CustomerSignupHttpError(409, 'TOKEN_ALREADY_USED')),
    'error.used',
  );
  assert.equal(
    customerSignupErrorKey(new CustomerSignupHttpError(410, 'TOKEN_EXPIRED')),
    'error.expired',
  );
});

test('dicionario do cadastro publico permanece em paridade', () => {
  assert.equal(assertPublicDictionaryParity(CUSTOMER_SIGNUP_DICTIONARY), true);
});

test('html publico de cadastro usa estrutura orientada pela empresa', () => {
  const source = readFileSync('web/public_customer_signup.html', 'utf8');

  assert.match(source, /class="catalog-page customer-signup-page"/);
  assert.match(source, /data-company-brand/);
  assert.match(source, /data-company-section/);
  assert.doesNotMatch(source, />SixoApp</);
});
