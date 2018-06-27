#  Installation
```bash
curl -O 'https://raw.githubusercontent.com/khtdr/rubidu/master/dist/rubidu'
chmod +x ./rubidu
./rubidu --test && ./rubidu -h
```
#  Self Describing Grammar
    root: *(ws assignment ws).
    assignment: identifier ws ":" ws +term ?block "." .
    identifier : +'-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890'.
    ws : *' \t\r\n'.
    block: ?("{\n" >"\n}" "\n}" ws).
    term : factor ?"!" ws.
    factor: ?'*+?' [identifier string chars until seq any].
    string: '"' >'"' '"'.
    chars : "'" >"'" "'".
    until:">"[string chars].
    seq: "(" ws +term ")".
    any: "[" ws +term "]".
