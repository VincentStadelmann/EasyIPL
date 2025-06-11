# EasyIPL

**EasyIPL** is a modular library of scripts written in [DCL (Digital Command Language)](https://en.wikipedia.org/wiki/Digital_Command_Language) for use with SCANCO's **IPL** image processing language on **OpenVMS** systems. It provides reusable components to accelerate the development and templating of microCT image analysis workflows.

## Requirements

- SCANCO microCT system running **OpenVMS**
- **IPL** scripting environment (standard on SCANCO systems)
- **ICALC** (optional but recommended; see below)

## Installation

1. **Create an EasyIPL folder** on your SCANCO system, for example:

   ```dcl
   $ CREATE/DIR ADISK1:[MICROCT.EASYIPL]
   ```

   *(Adapt address to your system & username)*

2. **Transfer the scripts:**

   Copy all `.COM` files from the `scripts/` folder of this repo into your EasyIPL folder using FTP.

3. **ICALC** is provided in the `icalc/` directory, in case it's not already installed.  
   Note: ICALC is not part of EasyIPL and is provided as-is.  
   UNZIP `ICALC.ZIP` in the `UT:` directory of your system.

## Setup

Edit your `MICROCT_SETUP_USER.COM` file to include the following lines:

```dcl
$! EasyIPL
$   DEFINE EZ ADISK1:[MICROCT.EASYIPL]
$   EZ    == "@EZ:HELP.COM"
$   MJ    == "@ADISK1:[MICROCT.EASYIPL]MONITOR_JOB.COM "
$   ICALC == "$UT:ICALC.EXE"
```

*(Replace `MICROCT` with your actual directory name.)*

## Folder structure

```
EasyIPL/
├── scripts/      # All .COM scripts
├── examples/     # Example use cases or applications
├── icalc/        # Optional ICALC binary
├── doc/          # Documentation (WIP)
└── dev/          # Unfinished business
```

## License

This project is released under an open license. See the `LICENSE` file for more information.  
**ICALC** is third-party and not maintained by this repository's author.

## Contributing

Suggestions, feedback, and improvements are welcome via Issues or Pull Requests.
