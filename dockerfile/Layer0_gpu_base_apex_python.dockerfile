# Base image with the following things installed
# python 3.7 (check)
# pip, conda, jupyter, jupyter extensions
# CUDA, CUDNN, APEX, pytorch


# https://github.com/NVIDIA/apex/tree/master/examples/docker
# Base image must at least have pytorch and CUDA installed.
ARG BASE_IMAGE=pytorch/pytorch:1.1.0-cuda10.0-cudnn7.5-devel
FROM $BASE_IMAGE
ARG BASE_IMAGE
RUN echo "Installing Apex on top of ${BASE_IMAGE}"
# make sure we don't overwrite some existing directory called "apex"
WORKDIR /tmp/unique_for_apex
# uninstall Apex if present, twice to make absolutely sure :)
RUN pip uninstall -y apex || :
RUN pip uninstall -y apex || :
# SHA is something the user can touch to force recreation of this Docker layer,
# and therefore force cloning of the latest version of Apex
RUN SHA=ToUcHMe git clone https://github.com/NVIDIA/apex.git
WORKDIR /tmp/unique_for_apex/apex
RUN pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" .
WORKDIR /


# https://docs.docker.com/engine/examples/running_ssh_service/
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:some_pass' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN mkdir ~/.ssh/
RUN touch ~/.ssh/authorized_keys


# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
# writing env variables to /etc/profile as mentioned here
# https://docs.docker.com/engine/examples/running_ssh_service/#run-a-test_sshd-container
RUN echo "export VISIBLE=now" >> /etc/profile


RUN apt-get update && \
    apt-get install -y wget git libhdf5-dev g++ graphviz openmpi-bin nano && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.5.12-Linux-x86_64.sh && \
    echo "866ae9dff53ad0874e1d1a60b1ad1ef8 *Miniconda3-4.5.12-Linux-x86_64.sh" | md5sum -c - && \
    ln /usr/lib/x86_64-linux-gnu/libcudnn.so /usr/local/cuda/lib64/libcudnn.so && \
    ln /usr/lib/x86_64-linux-gnu/libcudnn.so.7 /usr/local/cuda/lib64/libcudnn.so.7 && \
    ln /usr/include/cudnn.h /usr/local/cuda/include/cudnn.h


RUN apt-get install -y sox libsox-dev libsox-fmt-all


# writing env variables to /etc/profile as mentioned here
# https://docs.docker.com/engine/examples/running_ssh_service/#run-a-test_sshd-container
RUN echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH" >> /etc/profile
RUN echo "export CPATH=/usr/include:/usr/include/x86_64-linux-gnu:/usr/local/cuda/include:$CPATH" >> /etc/profile
RUN echo "export LIBRARY_PATH=/usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LIBRARY_PATH" >> /etc/profile
RUN echo "export CUDA_HOME=/usr/local/cuda" >> /etc/profile
RUN echo "export CPLUS_INCLUDE_PATH=$CPATH" >> /etc/profile
RUN echo "export KERAS_BACKEND=tensorflow" >> /etc/profile


ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
RUN echo "export CONDA_DIR=/opt/conda" >> /etc/profile
RUN echo "export PATH=$CONDA_DIR/bin:$PATH" >> /etc/profile


RUN pip install --upgrade pip
RUN conda install notebook=5.6
RUN pip install git+https://github.com/ipython-contrib/jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user


ENV CUDA_HOME /usr/local/cuda
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV CPATH /usr/include:/usr/include/x86_64-linux-gnu:/usr/local/cuda/include:$CPATH
ENV LIBRARY_PATH /usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LIBRARY_PATH
ENV CPLUS_INCLUDE_PATH $CPATH
ENV KERAS_BACKEND tensorflow



