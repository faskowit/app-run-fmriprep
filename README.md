[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.160-blue.svg)](https://doi.org/10.25663/brainlife.app.160)

# app-run-fmriprep

version 0.0.3

This app runs [fMRIPrep](https://github.com/poldracklab/fmriprep) on the [brainlife.io](https://brainlife.io/) interface. fMRIPrep is a robust processing tool delevoped by the [Poldrack Lab at Stanford](https://poldracklab.stanford.edu/). The pipelines process T1w, T2w, fMRI, and fieldmaps by calling a series of functions from FSL, FreeSurfer, ANTs, and nipy. It applies these tools in a principled way designed to handle common imaging artifacts and biases in a parimonious manner. It outputs processed anatomical and functional images for further analysis. 

* fMRIPrep paper: [nature methods paper](https://doi.org/10.1038/s41592-018-0235-4)
* fMRIPrep documentation: [read the docs](https://fmriprep.readthedocs.io/en/stable/)
* fMRIPrep also provides documentation to credit the tools employed in the pipeline: [citing tools](https://fmriprep.readthedocs.io/en/stable/citing.html)

### Authors
- Josh Faskowitz ([@faskowit](https://github.com/faskowit))
- Soichi Hayashi ([@soichih](https://github.com/soichih))

### Project director
- Franco Pestilli ([@francopestilli](https://github.com/francopestilli))

### Funding 
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-1342962](https://img.shields.io/badge/NSF_DGE-1342962-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1342962)

## Running the App 

### On Brainlife.io

Check out the brainlife app [here](https://doi.org/10.25663/brainlife.app.160)

### Running Locally

A
  1) git clone this repo.
  2) Inside the cloned directory, create `config.json` with something like the following content with paths to your input files.

  ```json
  {
    "t1": "./t1.nii.gz",
    "fmri": "./bold.nii.gz",
    "freesurfer": "./fsdir"
  }
  ```

  3. Launch the App by executing `main`

  ```bash
  ./main
  ```
 
B
  1) Alternatively, there is a command line interface useful for debugging.

## Output

This app outputs the completed fmriprep dir, along with some of the outputs mapped for the brainlife interface.

### Dependencies

This App requires [singularity](https://www.sylabs.io/singularity/) to run. If you don't have singularity, you will need to install following dependencies. It also requires [jq](https://stedolan.github.io/jq/).

---

### Notes.
This material is based upon work supported by the National Science Foundation Graduate Research Fellowship under Grant No. 1342962. Any opinion, findings, and conclusions or recommendations expressed in this material are those of the authors(s) and do not necessarily reflect the views of the National Science Foundation.
