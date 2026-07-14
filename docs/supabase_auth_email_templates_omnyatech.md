# Templates de e-mail Supabase Auth - OmnyaTech

Data: 2026-07-14

Objetivo: padronizar os e-mails do Supabase Auth compartilhado para a marca
OmnyaTech. Como o Supabase Auth e o SMTP estao no mesmo projeto usado por mais
de um app, estes templates evitam citar OmnyaFinance como produto especifico e
tratam o Driver como produto da OmnyaTech.

Logo usado:
`https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png`

## Confirm Sign Up

Assunto: `Confirme seu cadastro na OmnyaTech`

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
        <tr><td style="background:#0000CD;padding:28px 32px;text-align:center;">
          <img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;">
        </td></tr>
        <tr><td style="padding:36px 32px;">
          <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Confirme seu cadastro</h1>
          <p style="margin:0 0 16px;font-size:16px;line-height:1.6;color:#374151;">Ola,</p>
          <p style="margin:0 0 24px;font-size:16px;line-height:1.6;color:#374151;">Seu cadastro em um produto da <strong>OmnyaTech</strong> foi iniciado. Confirme seu e-mail para ativar sua conta com seguranca.</p>
          <p style="margin:0 0 28px;text-align:center;"><a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0000CD;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 24px;border-radius:12px;">Confirmar e-mail</a></p>
          <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">Se voce nao criou uma conta em um produto da OmnyaTech, ignore este e-mail.</p>
        </td></tr>
        <tr><td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;"><p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p></td></tr>
      </table>
    </td></tr>
  </table>
</div>
```

## Reset Password

Assunto: `Redefina sua senha da OmnyaTech`

```html
<div style="margin:0;padding:0;background:#f4f4f6;font-family:Arial,Helvetica,sans-serif;color:#111827;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f4f4f6;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="max-width:640px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e5e7eb;">
        <tr><td style="background:#0000CD;padding:28px 32px;text-align:center;"><img src="https://raw.githubusercontent.com/Yan-Oliv/omnyatech-images/main/logos/fundo%20transparente/Logo_completo_com_fundo_escuro_e_com_texto_OmnyaTech-transp.png" alt="OmnyaTech" style="max-width:220px;width:100%;height:auto;display:block;margin:0 auto;"></td></tr>
        <tr><td style="padding:36px 32px;">
          <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#000000;">Redefina sua senha</h1>
          <p style="margin:0 0 24px;font-size:16px;line-height:1.6;color:#374151;">Recebemos uma solicitacao para redefinir a senha da sua conta em um produto da <strong>OmnyaTech</strong>.</p>
          <p style="margin:0 0 28px;text-align:center;"><a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0000CD;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;padding:14px 24px;border-radius:12px;">Redefinir senha</a></p>
          <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">Se voce nao solicitou a redefinicao de senha, ignore este e-mail.</p>
        </td></tr>
        <tr><td style="background:#f9fafb;border-top:1px solid #e5e7eb;padding:20px 32px;text-align:center;"><p style="margin:0;font-size:13px;color:#6b7280;">OmnyaTech</p></td></tr>
      </table>
    </td></tr>
  </table>
</div>
```

## Invite User

Assunto: `Voce foi convidado para a OmnyaTech`

Use o mesmo HTML do `Confirm Sign Up`, trocando:

- Titulo: `Aceite seu convite`
- Texto principal: `Voce recebeu um convite para acessar um produto da OmnyaTech. Toque no botao abaixo para criar sua conta com seguranca.`
- Botao: `Aceitar convite`
- Rodape de seguranca: `Se voce nao esperava este convite, ignore este e-mail.`

## Magic Link or OTP

Assunto: `Seu codigo de acesso da OmnyaTech`

Use o mesmo HTML do `Confirm Sign Up`, trocando:

- Titulo: `Acesse sua conta`
- Texto principal: `Use o botao abaixo para entrar com seguranca em um produto da OmnyaTech.`
- Botao: `Entrar com seguranca`
- Texto extra opcional: `Codigo: <strong>{{ .Token }}</strong>`
- Rodape de seguranca: `Se voce nao tentou entrar, ignore este e-mail.`

## Change Email Address

Assunto: `Confirme a alteracao do seu e-mail`

Use o mesmo HTML do `Confirm Sign Up`, trocando:

- Titulo: `Confirme seu novo e-mail`
- Texto principal: `Recebemos uma solicitacao para alterar o e-mail da sua conta OmnyaTech para <strong>{{ .Email }}</strong>.`
- Botao: `Confirmar novo e-mail`
- Rodape de seguranca: `Se voce nao solicitou esta alteracao, ignore este e-mail e revise a seguranca da sua conta.`

## Reauthentication

Assunto: `Confirme sua identidade na OmnyaTech`

Use o mesmo HTML do `Confirm Sign Up`, trocando:

- Titulo: `Confirme sua identidade`
- Texto principal: `Para continuar uma acao sensivel, confirme que e voce acessando sua conta OmnyaTech.`
- Botao: `Confirmar identidade`
- Texto extra opcional: `Codigo: <strong>{{ .Token }}</strong>`
- Rodape de seguranca: `Se voce nao iniciou esta acao, ignore este e-mail.`

## Security Notifications

Para `Password changed`, `Email address changed`, `Phone number changed`,
`Sign-in method linked`, `Sign-in method removed`, `MFA method added` e
`MFA method removed`, usar o mesmo layout visual com assunto e mensagem abaixo.
Esses e-mails nao precisam de CTA se o Supabase nao exigir link.

| Template | Assunto | Titulo | Mensagem |
| --- | --- | --- | --- |
| Password changed | `Sua senha OmnyaTech foi alterada` | `Senha alterada` | `A senha da sua conta OmnyaTech foi alterada com sucesso.` |
| Email address changed | `Seu e-mail OmnyaTech foi alterado` | `E-mail alterado` | `O e-mail da sua conta OmnyaTech foi alterado.` |
| Phone number changed | `Seu telefone OmnyaTech foi alterado` | `Telefone alterado` | `O telefone da sua conta OmnyaTech foi alterado.` |
| Sign-in method linked | `Novo metodo de login conectado` | `Metodo de login conectado` | `Um novo metodo de login foi conectado a sua conta OmnyaTech.` |
| Sign-in method removed | `Metodo de login removido` | `Metodo de login removido` | `Um metodo de login foi removido da sua conta OmnyaTech.` |
| MFA method added | `Novo MFA conectado a sua conta` | `MFA conectado` | `Um novo metodo de autenticacao multifator foi conectado a sua conta OmnyaTech.` |
| MFA method removed | `MFA removido da sua conta` | `MFA removido` | `Um metodo de autenticacao multifator foi removido da sua conta OmnyaTech.` |

Rodape recomendado para todos:
`Se voce nao reconhece esta acao, altere sua senha e fale com o suporte da OmnyaTech.`
