#!/usr/bin/env ruby

TMPL = <<-EOF
  <Binding name='OBINDINGS%{id}' hidden='true'>
    if oBindings%{id} then
      oBindings%{id}:Click()
    end
  </Binding>
EOF

File.open('Bindings.xml', 'w') do |file|
  file.puts('<Bindings>')
  (1..60).each do |id|
    file.write(TMPL % { id: id })
  end
  file.puts('</Bindings>')
end
