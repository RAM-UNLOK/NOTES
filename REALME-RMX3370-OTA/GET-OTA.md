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
realme-ota -v 4 -r 0 RMX3370 RMX3370_11.F.13_3130_202309251336 4 -d DUMPGL.md
```
```
realme-ota -v 4 -r 1 RMX3370 RMX3370_11.F.13_3130_202309251336 4 -d DUMPCN.md
```
```
realme-ota -v 4 -r 2 RMX3370 RMX3370_11.F.13_3130_202309251336 4 -d DUMPIN.md
```
```
realme-ota -v 4 -r 3 RMX3370 RMX3370_11.F.13_3130_202309251336 4 -d DUMPEU.md
```


## Click To Download

### Global

- [RMX3370_11.F.14 Global OTA DUMP](https://gauss-componentotacostmanual-sg.allawnofs.com/remove-f4aedc728028cb0abef1b3ea8ae617b2/component-ota/23/12/04/79f58c25fe6240868c0afe694d688c0f.zip)

- [RMX3370_11.F.14 Global OTA INFO](https://gauss-componentotacostmanual-sg.allawnofs.com/remove-f4aedc728028cb0abef1b3ea8ae617b2/component-ota/23/12/13/6ffc39cd71f54175ab26f9ab7fb798fb.html?logoType=1)

### Europe

- [RMX3370_11.F.14 Europe OTA DUMP](https://gauss-componentotacostmanual-eu.allawnofs.com/remove-7e59eaeed4aa6579539c133bd617eab1/component-ota/23/12/04/e20417e86f4e4811b9e371b55aab1814.zip)

- [RMX3370_11.F.14 Europe OTA INFO](https://gauss-componentotacostmanual-eu.allawnofs.com/remove-7e59eaeed4aa6579539c133bd617eab1/component-ota/23/12/05/b439f20da94744d6b99d54fa3ea6a46f.html?logoType=1)

### India

- [RMX3370_11.F.14 India OTA DUMP](https://gauss-componentotacostmanual-in.allawnofs.com/remove-f4aedc728028cb0abef1b3ea8ae617b2/component-ota/23/12/04/79f58c25fe6240868c0afe694d688c0f.zip)

- [RMX3370_11.F.14 India OTA INFO](https://gauss-componentotacostmanual-in.allawnofs.com/remove-f4aedc728028cb0abef1b3ea8ae617b2/component-ota/23/12/13/6ffc39cd71f54175ab26f9ab7fb798fb.html?logoType=1)
