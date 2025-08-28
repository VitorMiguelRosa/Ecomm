require 'pagy/extras/bootstrap'

# Configurações do Pagy  
Pagy::DEFAULT[:limit]      = 4             # Itens por página
Pagy::DEFAULT[:page_param] = :page         # Nome do parâmetro da página
Pagy::DEFAULT[:overflow]   = :last_page    # Comportamento quando página não existe

# Para limitar o número de páginas na navegação, usaremos uma abordagem customizada