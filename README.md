## Gitflow

Este projeto utiliza um modelo estruturado de Gitflow para organizar o desenvolvimento e manter a qualidade do código.

### Branches Principais

- **main**  
  Contém a versão estável do código, utilizada para releases e distribuição.

- **develop**  
  Representa o estado atual do desenvolvimento. Todas as novas funcionalidades e correções passam por essa branch antes de serem promovidas à main.

### Branches de Trabalho

- **feature/nome-da-feature**  
  Utilizada para desenvolvimento de novas funcionalidades.

- **fix/nome-do-fix**  
  Utilizada para correções.

### Regras Gerais

1. Commits diretos para `main` e `develop` não são permitidos.  
2. Todo fluxo de contribuição é feito através de Pull Requests.  
3. Pull Requests direcionados para:
   - `develop` para desenvolvimento contínuo,
   - `main` para releases ou hotfixes.
4. Cada Pull Request deve ser revisado e aprovado conforme as regras definidas pelo projeto.
5. Merges devem seguir as políticas configuradas no repositório, incluindo aprovações obrigatórias e checks automatizados.

### Fluxo Resumido

1. Criar branch a partir de `develop`.  
2. Implementar a tarefa na branch correspondente.  
3. Abrir Pull Request para `develop`.
4. Obter aprovações necessárias. 
5. Finalizar o merge seguindo as proteções da branch.  
6. Após merge na `main`, os pipelines de deploy podem ser acionados automaticamente (se configurados).
