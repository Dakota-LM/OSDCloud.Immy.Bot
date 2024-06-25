# OSDCloud + ImmyBot
Scripts to bring together these two great technologies.

```mermaid
flowchart TD
    A{Run Hydration Pack} --> B
    B("Run New-OSDCloudUSB \n(or Update-OSDCloudUSB)") --> C
    C(Add ImmyBot Provisioning Package to USB) --> D
    D{Deploy!}
```
