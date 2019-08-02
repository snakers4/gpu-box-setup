FROM aveysov/ml_images:layer-0


RUN conda install Pillow scikit-learn notebook pandas matplotlib mkl nose pyyaml six h5py && \
    conda install bcolz && \
    conda install feather-format -c conda-forge && \
    conda install -c conda-forge umap-learn && \
    conda install datashader && \
    conda install -c conda-forge hdbscan && \
    conda clean -yt


RUN pip install tensorflow-gpu && \
    pip install keras opencv-python scipy tqdm visdom && \
    pip install tensorboardX && \
    pip install sqlalchemy pymysql && \
    pip install telethon PySocks requests && \
    pip install tabulate seaborn natasha pymorphy2 transliterate matplotlib-venn sentencepiece ftfy && \
    pip install -U nltk && \
    pip install git+https://github.com/facebookresearch/fastText.git
