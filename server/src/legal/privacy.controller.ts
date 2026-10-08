import { Controller, Get, Header, Inject } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { AppConfig, appConfig } from '../config/app.config';

/** Paths of the privacy policy, outside the `/api` prefix (see app.setup.ts). */
export const PRIVACY_PATHS = ['confidentialite', 'privacy'];

/** The address of the policy before it is published. */
const PLACEHOLDER = 'contact@example.org';

/**
 * The privacy policy of the app, at `/confidentialite` and `/privacy`.
 * Google Play asks for its address, and for that of its "Delete your
 * account" section (`/confidentialite#suppression`).
 */
@Controller()
export class PrivacyController {
  private readonly page: string;

  constructor(@Inject(appConfig.KEY) settings: AppConfig) {
    const html = readFileSync(join(__dirname, 'privacy-policy.html'), 'utf8');
    this.page = settings.contactEmail ? html.replaceAll(PLACEHOLDER, settings.contactEmail) : html;
  }

  @Get(PRIVACY_PATHS)
  @Header('Content-Type', 'text/html; charset=utf-8')
  @Header('Cache-Control', 'public, max-age=3600')
  policy(): string {
    return this.page;
  }
}
