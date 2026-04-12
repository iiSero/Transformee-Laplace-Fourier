import os
import sys
from image_traitement import LoadingWindow
from PyQt5.QtWidgets import (
    QApplication, 
    QWidget, 
    QLabel, 
    QHBoxLayout, 
    QPushButton, 
    QFileDialog, 
    QVBoxLayout,
    QSlider)
from PyQt5.QtCore import QSize, Qt
from PyQt5.QtGui import QImage ,QPixmap, QIcon
from PIL import Image
import time

def pil_to_qpixmap(pil_image):
     '''
     Permet de convertir les images de PIL en une image lisible et utilisable par PyQt
     '''
     pil_image = pil_image.convert("RGB")
     data = pil_image.tobytes("raw", "RGB")
     qimage = QImage(data, pil_image.size[0], pil_image.size[1], QImage.Format_RGB888)
     qimage = QPixmap.fromImage(qimage)
     return  qimage.scaled(300, 300, Qt.KeepAspectRatio)



class MainWindow(QWidget):
    '''
    La fenêtre principale du logiciel
    '''
    def update_label(self):
        '''
        Permet d'afficher  les modifications du coefficient de compression en temps réel
        '''
        self.labelslider.setText(str(self.slider.value()))
        self.coef = self.slider.value()
        
    def __init__(self, *args, **kwargs):
        #On initialise tout d'abord une fenêtre "de base"

        super().__init__(*args, **kwargs)

        # Modification des paramètres de la fenêtre de base (nom, icone, etc.)

        self.setWindowTitle('Cobra')
        self.setGeometry(0, 0, 1920, 1080)
        self.setWindowIcon(QIcon('./logiciel_traitement/DONT_DELETE/icon.png'))

        #Création des widgets

        self.link = ""
        self.label = QLabel("Veuillez selectionner un fichier")
        self.imi = QLabel()
        self.imf = QLabel()
        self.fr = QLabel()
        self.fg = QLabel()
        self.fb = QLabel()
        self.label1 = QLabel("\n \n" + " "*30 +"IMAGE INITIALE")
        self.label2 = QLabel("\n \n"+"IMAGE FINALE")
        self.label3 = QLabel("\n \n"+ " "*25+"FILTRES")
        self.poids2 = QLabel()
        self.poids3 = QLabel()
        self.slider = QSlider(Qt.Orientation.Horizontal)
        self.slider.setRange(0, 100000) 
        self.slider.setValue(1000)
        self.slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.slider.setTickInterval(1000) 
        self.slider.setSingleStep(5) 
        self.slider.valueChanged.connect(self.update_label)
        self.labelslider = QLabel(str(self.slider.value()))

        
        
        self.image = QPixmap()
        
        self.valider = QPushButton()
        self.button = QPushButton()
        self.layout = QVBoxLayout()
        self.V1layout = QVBoxLayout()
        self.V2layout = QVBoxLayout()
        self.V3layout = QVBoxLayout()
        self.Hlayout = QHBoxLayout()
        self.H0layout = QHBoxLayout()
        self.H1layout = QHBoxLayout()
        self.V4layout = QVBoxLayout()
  
       
       #Placement des widgets sur l'écran

        self.H0layout.addWidget(self.label)
        self.H0layout.addWidget(self.button)
        self.H0layout.addWidget(self.valider)
        self.H0layout.addWidget(self.slider)
        self.H0layout.addWidget(self.labelslider)
        self.H1layout.addWidget(self.label1)
        self.V1layout.addWidget(self.imi)
        self.H1layout.addWidget(self.label3)
        self.V3layout.addWidget(self.imf)
        self.H1layout.addWidget(self.label2)
        self.V2layout.addWidget(self.fr)
        self.V2layout.addWidget(self.fg)
        self.V2layout.addWidget(self.fb)
        self.V4layout.addWidget(self.poids2)
        self.V4layout.addWidget(self.poids3)

        self.V2layout.setContentsMargins(100, 0, 0, 0)
        self.V3layout.setContentsMargins(0, 0, 100, 0)

        self.layout.addLayout(self.H0layout)

        self.Hlayout.addLayout(self.V1layout)
        self.Hlayout.addLayout(self.V2layout)
        self.Hlayout.addLayout(self.V3layout)
        self.Hlayout.addLayout(self.V4layout)

        self.layout.addLayout(self.H1layout)
        self.layout.addLayout(self.Hlayout)
        

        self.button.setFixedSize(QSize(100, 30))
        self.button.setIcon(QIcon('./logiciel_traitement/DONT_DELETE/folder.png'))
        self.button.clicked.connect(self.open)

        self.valider.setFixedSize(QSize(100, 30))
        self.valider.setText("Valider")
        self.valider.clicked.connect(self.validation)


        self.imi.setFixedSize(QSize(375, 300))
        self.imf.setFixedSize(QSize(375, 300))
        self.fr.setFixedSize(QSize(200, 200))
        self.fg.setFixedSize(QSize(200, 200))
        self.fb.setFixedSize(QSize(200, 200))

        self.label1.setGeometry(320,0,370,20)
        self.label2.setGeometry(850,0,900,20)
        self.label3.setGeometry(1275,0,1325,20)

        self.setLayout(self.layout)
        
        #Affichage de la fenêtre

        self.show()
    
   
    
    def open(self):
            '''
            Permet d'ouvrir un fichier image  depuis notre machine
            '''

            #Ouvrir l'explorateur de fichiers

            file_path, _ = QFileDialog.getOpenFileName(
            window, 
            "Ouvrir un fichier", 
            "", 
            "Tous les fichiers (*);;Fichiers texte (*.txt)"
            )

            # Cas où l'utilisateur a selectionné une image

            if file_path:

                #Afficher l'image choisie sur l'écran

                self.label.setText(f"Fichier sélectionné : {file_path}")
                *_,imi_format = file_path.split(".")

                # Si l'image est du format jpg, PyQt ne peut pas l'afficher directement, il faut donc la convetir

                if imi_format == "jpg":
                    im = Image.open(file_path)
                    im = im.convert("RGB")
                    data = im.tobytes("raw","RGB")
                    qim = QImage(data, im.size[0], im.size[1], QImage.Format_RGB888)
                    self.image = QPixmap.fromImage(qim)
                    self.image = self.image.scaled(375, 300, Qt.KeepAspectRatio)
                    self.imi.setPixmap(self.image)

                
                #Si l'image est du format png ou autres on peut l'afficher directement avec PyQt
                # N'hésitez pas à me signaler tout format ne pouvant être traité de cette manière que je n'ai pas testé
                  
                else:
                     self.image = QPixmap(file_path)
                     self.image = self.image.scaled(375, 300, Qt.KeepAspectRatio)
                     self.imi.setPixmap(self.image)
                

                # On couvre égalment le cas "bug" où l'image chargée est nulle

                if self.image.isNull():
                     print("problème!")
                self.link = file_path


            # Cas où l'utilisateur n'a choisi aucune image
              
            else:
                self.label.setText("Aucun fichier sélectionné")

    
    def validation(self):
            '''

            Permet de valider l'image choisie et de commencer les calculs

            '''
            # Cas où l'utilisateur valide sans avoir chargé d'image auparavant

            if self.link  == "":
                self.label.setText("Veuillez charger une image !")

            #Cas où l'utilisateur a effectivement choisi une image sur sa machine

            elif isinstance(self.link,str):
                img = Image.open(self.link)
                *_,format = self.link.split(".")

                # On crée la fenêtre de chargement qui se chargera de traiter l'image

                self.loading_window = LoadingWindow(self,img,int(self.slider.value()))
                
                
                
    
#Lancer le logiciel lorsque l'on exécute ce programme en tant que module principal
if __name__ == '__main__':
    app = QApplication(sys.argv)

    # Permet de créer la fenêtre que l'on a définie

    window = MainWindow()
    sys.exit(app.exec())