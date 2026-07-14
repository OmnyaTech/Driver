# Templates de e-mail Supabase Auth - OmnyaTech

Atualizado em 2026-07-14.

Este documento padroniza os e-mails do Supabase Auth para a marca
**OmnyaTech**, evitando referencias especificas a OmnyaFinance ou Driver quando
o mesmo projeto Supabase atender mais de um aplicativo.

## Estado Atual Levantado

Os templates atuais no Supabase usam o layout visual da OmnyaTech, mas ainda
citam `OmnyaFinance` nos assuntos, textos e rodapes.

Templates revisados:

- Confirm sign up
- Invite user
- Magic link or OTP
- Change email address
- Reset password
- Reauthentication
- Password changed
- Email address changed
- Sign-in method linked
- Sign-in method removed
- MFA method added
- MFA method removed

## Remetente Recomendado

Hoje os e-mails aparecem como:

- Nome: `Supabase Auth`
- E-mail: `noreply@mail.app.supabase.io`

Para enviar como empresa, configure SMTP customizado no Supabase em:

`Authentication > Emails > SMTP Settings`

Recomendado para producao:

- Sender name: `OmnyaTech`
- Sender email: `suporte@omnyatech.com.br`
- Reply-to: `suporte@omnyatech.com.br`

Alternativa aceitavel enquanto o dominio nao estiver 100% pronto:

- Sender name: `OmnyaTech`
- Sender email: `omnyatech@gmail.com`

Observacoes:

- O ideal e usar `suporte@omnyatech.com.br`, porque reforca a marca e evita
  que produtos profissionais saiam de um Gmail pessoal.
- Se usar Gmail SMTP, o e-mail remetente precisa estar autorizado/verificado na
  conta Gmail/Google Workspace usada no SMTP.
- Para melhor entregabilidade em producao, prefira um provedor transacional
  com dominio verificado, como Resend, Postmark, SendGrid, Brevo ou AWS SES.
- O Supabase recomenda SMTP customizado para apps de producao. Sem isso, o
  projeto continua usando o remetente padrao `Supabase Auth`.

Config basica para Gmail SMTP, se for usar Gmail:

```text
Host: smtp.gmail.com
Port: 587
Username: omnyatech@gmail.com
Password: senha de app do Google
Sender name: OmnyaTech
Sender email: suporte@omnyatech.com.br ou omnyatech@gmail.com
Minimum interval between emails: manter o padrao do Supabase ou ajustar com cuidado
```

## Logo

URL usada nos templates:

```text
https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png
```

## Confirm Sign Up

Assunto:

```text
Confirme seu cadastro na OmnyaTech
```

Conteudo:

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#0000CD;padding:28px 32px;text-align:center;">
              <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px;">
              <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Confirme seu cadastro</h1>
              <p style="margin:0 0 16px;font-size:16px;line-height:1.6;color:#374151;">Ola,</p>
              <p style="margin:0 0 24px;font-size:16px;line-height:1.6;color:#374151;">
                Seu cadastro em um produto da <strong>OmnyaTech</strong> foi iniciado. Confirme seu e-mail para ativar sua conta com seguranca.
              </p>
              <p style="margin:0 0 28px;text-align:center;">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0000CD;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 24px;border-radius:12px;">
                  Confirmar e-mail
                </a>
              </p>
              <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                Se voce nao criou uma conta em um produto da OmnyaTech, ignore este e-mail.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
```

## Invite User

Assunto:

```text
Voce foi convidado para a OmnyaTech
```

Conteudo:

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#0000CD;padding:28px 32px;text-align:center;">
              <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px;">
              <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Voce foi convidado</h1>
              <p style="margin:0 0 24px;font-size:16px;line-height:1.6;color:#374151;">
                Voce recebeu um convite para criar uma conta e acessar um produto da <strong>OmnyaTech</strong> com mais seguranca.
              </p>
              <p style="margin:0 0 28px;text-align:center;">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0000CD;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 24px;border-radius:12px;">
                  Aceitar convite
                </a>
              </p>
              <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                Se voce nao esperava este convite, ignore este e-mail.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
```

## Magic Link or OTP

Assunto:

```text
Seu acesso seguro da OmnyaTech
```

Conteudo:

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#0000CD;padding:28px 32px;text-align:center;">
              <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px;">
              <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Acesse sua conta</h1>
              <p style="margin:0 0 24px;font-size:16px;line-height:1.6;color:#374151;">
                Use o botao abaixo para entrar com seguranca em um produto da <strong>OmnyaTech</strong>.
              </p>
              <p style="margin:0 0 28px;text-align:center;">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0000CD;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 24px;border-radius:12px;">
                  Entrar com seguranca
                </a>
              </p>
              <p style="margin:0 0 12px;font-size:14px;line-height:1.6;color:#6b7280;text-align:center;">
                Codigo de acesso: <strong>{{ .Token }}</strong>
              </p>
              <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                Se voce nao solicitou este acesso, ignore este e-mail.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
```

## Change Email Address

Assunto:

```text
Confirme a alteracao do seu e-mail OmnyaTech
```

Conteudo:

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#0000CD;padding:28px 32px;text-align:center;">
              <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px;">
              <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Confirme a alteracao de e-mail</h1>
              <p style="margin:0 0 16px;font-size:16px;line-height:1.6;color:#374151;">
                Recebemos uma solicitacao para alterar o e-mail da sua conta OmnyaTech.
              </p>
              <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:12px;padding:16px;margin:0 0 24px;">
                <p style="margin:0 0 8px;font-size:14px;color:#374151;"><strong>De:</strong> {{ .Email }}</p>
                <p style="margin:0;font-size:14px;color:#374151;"><strong>Para:</strong> {{ .NewEmail }}</p>
              </div>
              <p style="margin:0 0 28px;text-align:center;">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0000CD;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 24px;border-radius:12px;">
                  Confirmar alteracao
                </a>
              </p>
              <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                Se voce nao solicitou esta alteracao, fale com o suporte da OmnyaTech imediatamente.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
```

## Reset Password

Assunto:

```text
Redefina sua senha da OmnyaTech
```

Conteudo:

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#0000CD;padding:28px 32px;text-align:center;">
              <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px;">
              <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Redefina sua senha</h1>
              <p style="margin:0 0 24px;font-size:16px;line-height:1.6;color:#374151;">
                Recebemos uma solicitacao para redefinir a senha da sua conta em um produto da <strong>OmnyaTech</strong>.
              </p>
              <p style="margin:0 0 28px;text-align:center;">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0000CD;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 24px;border-radius:12px;">
                  Redefinir senha
                </a>
              </p>
              <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                Se voce nao solicitou a redefinicao de senha, ignore este e-mail.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
```

## Reauthentication

Assunto:

```text
Codigo de reautenticacao OmnyaTech
```

Conteudo:

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#0000CD;padding:28px 32px;text-align:center;">
              <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px;">
              <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Confirme sua identidade</h1>
              <p style="margin:0 0 20px;font-size:16px;line-height:1.6;color:#374151;">
                Use o codigo abaixo para confirmar sua identidade antes de continuar uma acao sensivel.
              </p>
              <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:14px;padding:20px;text-align:center;margin:0 0 24px;">
                <p style="margin:0;font-size:32px;letter-spacing:6px;font-weight:800;color:#0000CD;">{{ .Token }}</p>
              </div>
              <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                Se voce nao solicitou esta acao, ignore este e-mail ou fale com o suporte da OmnyaTech.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
```

## Security Notification Base

Use este mesmo HTML para os templates de notificacao de seguranca. Troque
`{{TITLE}}` e `{{MESSAGE}}` conforme a tabela abaixo.

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
          <tr>
            <td style="background:#0000CD;padding:28px 32px;text-align:center;">
              <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px;">
              <h1 style="margin:0 0 16px;font-size:26px;color:#000000;">{{TITLE}}</h1>
              <p style="margin:0 0 16px;font-size:16px;line-height:1.6;color:#374151;">
                {{MESSAGE}}
              </p>
              <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                Se voce nao reconhece esta acao, altere sua senha e fale com o suporte da OmnyaTech imediatamente.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
```

## Security Notifications

| Template Supabase | Assunto | TITLE | MESSAGE |
| --- | --- | --- | --- |
| Password changed | `Sua senha OmnyaTech foi alterada` | `Sua senha foi alterada` | `Esta e uma confirmacao de que a senha da conta <strong>{{ .Email }}</strong> foi alterada.` |
| Email address changed | `Seu e-mail OmnyaTech foi alterado` | `Seu e-mail foi alterado` | `O e-mail da sua conta OmnyaTech foi alterado de <strong>{{ .OldEmail }}</strong> para <strong>{{ .Email }}</strong>.` |
| Phone number changed | `Seu telefone OmnyaTech foi alterado` | `Seu telefone foi alterado` | `O telefone da conta <strong>{{ .Email }}</strong> foi alterado.` |
| Sign-in method linked | `Novo metodo de login conectado` | `Novo metodo de login conectado` | `Uma nova identidade de acesso <strong>{{ .Provider }}</strong> foi vinculada a conta <strong>{{ .Email }}</strong>.` |
| Sign-in method removed | `Metodo de login removido` | `Metodo de login removido` | `A identidade de acesso <strong>{{ .Provider }}</strong> foi removida da conta <strong>{{ .Email }}</strong>.` |
| MFA method added | `Novo metodo de MFA adicionado` | `Novo metodo de MFA adicionado` | `Um novo fator de autenticacao <strong>{{ .FactorType }}</strong> foi adicionado a conta <strong>{{ .Email }}</strong>.` |
| MFA method removed | `Metodo de MFA removido` | `Metodo de MFA removido` | `O fator de autenticacao <strong>{{ .FactorType }}</strong> foi removido da conta <strong>{{ .Email }}</strong>.` |

## Checklist de Aplicacao no Supabase

1. Abrir `Authentication > Emails`.
2. Atualizar os assuntos e corpos HTML de cada template.
3. Abrir `Authentication > Emails > SMTP Settings`.
4. Habilitar Custom SMTP.
5. Configurar `Sender name` como `OmnyaTech`.
6. Configurar `Sender email` preferencialmente como `suporte@omnyatech.com.br`.
7. Enviar e-mail de teste.
8. Validar no Gmail recebido:
   - remetente aparece como `OmnyaTech`;
   - e-mail nao aparece mais como `Supabase Auth`;
   - assunto nao cita `OmnyaFinance`;
   - rodape mostra `OmnyaTech`;
   - links `{{ .ConfirmationURL }}` funcionam.
