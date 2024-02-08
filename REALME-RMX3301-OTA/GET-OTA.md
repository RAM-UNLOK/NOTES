### Realme GET-OTA Script

```
sudo apt install python3-pip
```
```
python3 -m venv .venv
```
```
source .venv/bin/activate
```
```
pip3 install --upgrade git+https://github.com/R0rt1z2/realme-ota
```

- -r (GL = 0, CN = 1, IN= 2, EU = 3)
- -v (RUI - 1 , 2 , 3 , 4 , 5 )
- -d (Filename = [ Global = DUMPGL , China = DUMPCN , India = DUMPIN , Europe = DUMPEU ] )

```
realme-ota -r 0 RMX3301 RMX3301_11.F.00_0000_000000000000 5 -d DUMPGL.md
```
```
realme-ota -r 2 RMX3301 RMX3301_11.F.00_0000_000000000000 5 -d DUMPIN.md
```


## Click To Download


### Global

- [RMX3301_11.F.22 OTA DUMP](https://gauss-componentotacostmanual-sg.allawnofs.com/remove-5eba5b14cf193dd0cc443bc8bb79d72f/component-ota/23/12/25/b6c242d31bb54a91b8a53bdb6dfaa4e8.zip)

- [RMX3301_11.F.22 OTA INFO](https://gauss-componentotacostmanual-sg.allawnofs.com/remove-5eba5b14cf193dd0cc443bc8bb79d72f/component-ota/24/01/10/5da1807885714fd68a2ff886ef4f94fc.html?logoType=1)

### India

- [RMX3301_11.F.22 OTA DUMP](https://gauss-componentotacostmanual-in.allawnofs.com/remove-5eba5b14cf193dd0cc443bc8bb79d72f/component-ota/23/12/25/b6c242d31bb54a91b8a53bdb6dfaa4e8.zip)

- [RMX3301_11.F.22 OTA INFO](https://gauss-componentotacostmanual-in.allawnofs.com/remove-5eba5b14cf193dd0cc443bc8bb79d72f/component-ota/24/01/10/5da1807885714fd68a2ff886ef4f94fc.html?logoType=1)
