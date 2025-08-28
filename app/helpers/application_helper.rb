module ApplicationHelper
  include Pagy::Frontend

  # Navegação customizada do Pagy com menos páginas
  def pagy_nav_compact(pagy, id: nil, aria_label: nil)
    id = %( id="#{id}") if id
    aria_label = %( aria-label="#{aria_label}") if aria_label
    
    # Link helper
    link = pagy_anchor(pagy)
    
    # Mostra apenas: primeira, atual, próxima e última
    html = %(<nav#{id} class="pagy nav"#{aria_label}>)
    
    # Botão anterior
    if pagy.prev
      html << link.call(pagy.prev, "‹")
    else
      html << %(<a role="link" aria-disabled="true" aria-label="Previous">‹</a>)
    end
    
    # Primeira página (só mostra se não for a atual)
    if pagy.page != 1
      html << link.call(1, "1")
      
      # Gap se necessário
      if pagy.page > 3
        html << %(<a role="link" aria-disabled="true" class="gap">…</a>)
      end
    end
    
    # Página atual
    html << %(<a role="link" aria-disabled="true" aria-current="page" class="current">#{pagy.page}</a>)
    
    # Última página (só mostra se não for a atual)
    if pagy.page != pagy.pages
      # Gap se necessário
      if pagy.page < pagy.pages - 2
        html << %(<a role="link" aria-disabled="true" class="gap">…</a>)
      end
      
      html << link.call(pagy.pages, pagy.pages.to_s)
    end
    
    # Botão próximo  
    if pagy.next
      html << link.call(pagy.next, "›")
    else
      html << %(<a role="link" aria-disabled="true" aria-label="Next">›</a>)
    end
    
    html << %(</nav>)
    html.html_safe
  end

end
