# Model Trainining Notes

This notebook deals with the training of the YOLO model used in this example. It includes

* The `conda` environment used (includes Keras and other packages' versions)
* Datasets used to train
* Notes for the conversion of the Keras model to CoreML

## Yolo Model

The current version of Yolo used in this example is YOLO V1 (there are newer models, but I am using this one since I know that it has been succesfully converterd to CoreML by othes). The YOLO Oaproach is described here: https://arxiv.org/abs/1612.08242

More specifically we will use Tiny YOLO to deal with the constrains of the mobile environment. At some point in the future we will need to investigate using YOLO v3 and also a larger model than the *Tiny* version if accuracy or performace become an issue.

### YOLO Model Training

The Yolo model training is done using a notebook in the `notebooks` directory. However note that only the notebook is included in the git repo since the weigths and image datasets are too large to store in the git repo.


More specifically we will use Tiny YOLO to deal with the constrains of the mobile environment. At some point in the future we will need to investigate using YOLO v3 and also a larger model than the *Tiny* version if accuracy or performace become an issue.



