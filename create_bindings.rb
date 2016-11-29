#!/usr/bin/env ruby

TMPL = <<-EOF
  <Binding name='OBINDINGS%{id}' hidden='true'>
    oBindings%{id}:Click()
  </Binding>
EOF

File.open('Bindings.xml', 'w') do |file|
  file.puts('<Bindings>')
  (1..60).each do |id|
    file.write(TMPL % { id: id })
  end
  file.puts('</Bindings>')
end
