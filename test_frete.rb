require 'bundler/setup'
require 'correios-frete'

begin
  calculador = Correios::Frete::Calculador.new(
    cep_origem: '83601-030',
    cep_destino: '01310-100',
    peso: 1,
    comprimento: 20,
    largura: 15,
    altura: 10
  )

  resultado = calculador.calcular(:sedex)
  puts "Valor: #{resultado.valor}"
  puts "Prazo: #{resultado.prazo_entrega}"
rescue => e
  puts "Erro: #{e.class} - #{e.message}"
end
