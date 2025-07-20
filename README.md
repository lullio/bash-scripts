## Estrutura

- `bin/` — scripts executáveis, sub­pastas por categoria  
- `config/` — meus dotfiles (zsh, vim, tmux…)  
- `docs/` — manuais e HOWTOs

## Usando um script

1. Ajuste as variáveis em `~/bin/backup-sites.sh` (pastas, remotes, credenciais). 
2. chmod +x ~/bin/backup-sites.sh
3. Agende no cron `crontab -e`

```bash
# Exemplo: todo dia às 4h da manhã
0 4 * * * /home/usuario/bin/backup-sites.sh >> /home/usuario/bin/backup-sites.log 2>&1
```