FROM aveysov/ml_images:layer-1

# ENV NB_UID 1000
ARG NB_UID

# create your user as the last step of the build
# NB_UID is passed as env variable
ENV NB_USER keras
RUN echo "export NB_USER=keras" >> /etc/profile
RUN echo "export NB_UID=1000" >> /etc/profile
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER


USER keras
RUN mkdir -p /home/keras/notebook
RUN mkdir ~/.ssh/
RUN touch ~/.ssh/authorized_keys


RUN jupyter contrib nbextension install --user


WORKDIR /home/keras/notebook
EXPOSE 8888 6006 22 8097
CMD jupyter notebook --port=8888 --ip=0.0.0.0 --no-browser
