import os
import sys
from PIL import Image, ImageDraw
import numpy as np
from PyQt5.QtWidgets import (
    QApplication, 
    QWidget, 
    QLabel,  
    QVBoxLayout,
    QProgressBar)
from PyQt5.QtCore import Qt,QThread, pyqtSignal
from PyQt5.QtGui import QImage ,QPixmap, QIcon


def pil_to_qpixmap(pil_image):
    '''
    Permet de convertir une image PIL en une image utilisable par PyQt
    '''
    pil_image = pil_image.convert("RGB")
    data = pil_image.tobytes("raw", "RGB")
    qimage = QImage(data, pil_image.size[0], pil_image.size[1], QImage.Format_RGB888)
    qimage = QPixmap.fromImage(qimage)
    return  qimage.scaled(375, 300, Qt.KeepAspectRatio)


class Worker(QThread):

    # Le worker permet de garder à jour la barre de progression pendant l'exécution du programme

    progress = pyqtSignal(int)

    def __init__(self, mainwindow,loadingwindow,image, coef):
        super().__init__()
        self.image = image
        self.coef = coef
        self.mainwindow = mainwindow
        self.loadingwindow = loadingwindow
    


    def run(self):
        '''
        Lance les calculs des filtres et de l'image reconstituée ainsi que leur affichage
        '''
        self.total = 4*self.image.width * self.image.height
        self.count = 0

        #Partie calcul des filtres et de l'image reconstituée

        self.résultat = Compression_Couleur(self.loadingwindow,self.image,self.coef)
        if self.résultat != None:
                    self.image_compressee, self.filtres = self.résultat
        else:
            self.label.setText("Erreur dans l'éxécution du programme")
            print("None")
            return
        
        # Affichage des filtres et de l'image reconstituée sur l'écran

        self.image_compressee.save('./logiciel_traitement/DONT_DELETE/transformée1.png')
        self.filtres[0].save('./logiciel_traitement/DONT_DELETE/filtre-rouge.png')
        self.filtres[1].save('./logiciel_traitement/DONT_DELETE/filtre-vert.png')
        self.filtres[2].save('./logiciel_traitement/DONT_DELETE/filtre-bleu.png')


        img_finale = QPixmap('./logiciel_traitement/DONT_DELETE/transformée1.png')
        img_finale = img_finale.scaled(375, 300, Qt.KeepAspectRatio)
        filtre_rouge = QPixmap('./logiciel_traitement/DONT_DELETE/filtre-rouge.png')
        filtre_rouge = filtre_rouge.scaled(300, 200, Qt.KeepAspectRatio)
        filtre_vert= QPixmap('./logiciel_traitement/DONT_DELETE/filtre-vert.png')
        filtre_vert = filtre_vert.scaled(300, 200, Qt.KeepAspectRatio)
        filtre_bleu= QPixmap('./logiciel_traitement/DONT_DELETE/filtre-bleu.png')
        filtre_bleu = filtre_bleu.scaled(300, 200, Qt.KeepAspectRatio)

        self.mainwindow.imf.setPixmap(img_finale)
        self.mainwindow.fr.setPixmap(filtre_rouge)
        self.mainwindow.fg.setPixmap(filtre_vert)
        self.mainwindow.fb.setPixmap(filtre_bleu)

        # On affiche également le poids de chque image affichée

        size_img_finale = os.path.getsize('./logiciel_traitement/DONT_DELETE/transformée1.png')
        size_filtre_rouge = os.path.getsize('./logiciel_traitement/DONT_DELETE/filtre-rouge.png')
        size_filtre_vert = os.path.getsize('./logiciel_traitement/DONT_DELETE/filtre-vert.png')
        size_filtre_bleu = os.path.getsize('./logiciel_traitement/DONT_DELETE/filtre-bleu.png')

        self.mainwindow.poids2.setText(f"POIDS DE L'IMAGE  'BRUTE' : \n {size_img_finale//1024} Ko")
        self.mainwindow.poids3.setText(f"POIDS DES FILTRES \n (i.e. de l'image compressée finale) : \n {(size_filtre_rouge + size_filtre_vert + size_filtre_bleu)//1024} Ko")



        self.loadingwindow.close()
           

    
class LoadingWindow(QWidget):
    def __init__(self, mainwindow,image, coef):

        #Encore une fois on initialise une fenêtre "de base"

        super().__init__()

        #Dont on va modifier les paramètres principaux

        self.setWindowTitle('Cobra is processing')
        self.setWindowIcon(QIcon('./logiciel_traitement/DONT_DELETE/icon.png'))
        self.setGeometry(400, 400, 500, 100)

        layout = QVBoxLayout()
        self.label = QLabel("Processing...")
        self.PG = QProgressBar()

        layout.addWidget(self.PG)
        layout.addWidget(self.label)
        self.setLayout(layout)


        # On initialise le worker qui va lancer les calculs 

        self.worker = Worker(mainwindow,self,image,coef)
        self.worker.progress.connect(self.PG.setValue)

        self.résultat = None
        

        #On lance le worker

        self.worker.start()

        # On affiche la fenêtre de chargement

        self.show()
        


    

def Compression_Gris(image):
    '''
    Version TEST : permet de compresser une image en noir et blanc (pas utilisée ici)
    '''
    filtre = dict()
    coef = min(image.height,image.width)
    image_f0 = Transformée_Image(image)
    Eliminer(image_f0,coef)
    filtre[0] = image_f0
    Dessiner(filtre)
    image_finale = np.fft.ifft2(image_f0)
    image_finale = [[list(row) for row in zip(*image_finale)]]
    return Dessiner(image_finale),filtre

def Compression_Couleur(window,image, coef):
    '''
    Permet de compresser une image tout en conservant les couleurs
    '''
    filtres = dict()
    filtres_images = []
    images = dict()

    #On réalise un filtrage pour chaque composante (rouge, vert et bleu) de l'image en couleur
    for color in range(1,4):
        
        image_f0 = Transformée_Image(image,color)
        Eliminer(image_f0,coef)
        filtres[color] = image_f0
        filtres[color] = [list(row) for row in zip(*filtres[color])]

        # On représente le filtre matrice en une image
        filtres_images.append(Dessiner([filtres[color]],window))


    #On reconstitue l'image couleur par couleur, à partir des trois filtres  
    for i in range(len(filtres)):
        images[i] = np.fft.ifft2(filtres[i+1])
        images[i] = [list(row) for row in zip(*images[i])]

    # On renvoie les images PIL de l'image reconstituée et de tous les filtres
    return Dessiner(images,window, iscolored = True),filtres_images
     




def Eliminer(matrice,coef):
    '''
    Permet de supprimer les coefficients de Fourier de module strictement inférieur à coef

    '''
    for i in range(len(matrice)):
        for j in range(len(matrice[0])):
            couleur = int(abs(matrice[i][j]))
            if couleur < coef:
                matrice[i][j] =0



def Transformée_Image(image,couleur :int =0):
    '''
    Prend une image en entrée, la convertit en matrice, puis applique 
    une Transformée de Fourier Discrète (ou TFD) sur cette matrice à l'aide du module NumPy
    '''
    image_a_traiter = Image_gris(image,couleur)
    image_transformee = np.fft.fft2(image_a_traiter)
    return image_transformee

def Image_gris(image,couleur :int = 0):
    '''
    Permet de convertir une image en niveau de gris en la transformant en matrice
    '''
    image_gris = Image.new("RGB", (image.width,image.height), (128, 128, 128))
    image_gris_matrice =[]
    draw = image_gris.load()
    for i in range(image.width):
        niveaux_gris_lignes = []
        for j in range(image.height):
            couleurs = image.getpixel((i,j))
            if couleur == 0:
                niveau_gris= (couleurs[0]+couleurs[1]+couleurs[2])//3
                niveaux_gris_lignes.append(niveau_gris)
                draw[i,j] = (niveau_gris,niveau_gris,niveau_gris)
            else:
                niveau_couleur = couleurs[couleur-1]
                niveaux_gris_lignes.append(niveau_couleur)
                draw[i,j] = (niveau_couleur,niveau_couleur,niveau_couleur)

        image_gris_matrice.append(niveaux_gris_lignes)

    return image_gris_matrice


def Dessiner(matrices, loading : LoadingWindow,iscolored :bool = False):
    '''
    Permet de transformer une matrice en image
    '''
    image_matrice = Image.new("RGB", (len(matrices[0]),len(matrices[0][0])), (128, 128, 128))
    draw0 = image_matrice.load()
    for i in range(len(matrices[0])):
        for j in range(len(matrices[0][0])):
                couleurs =[]
                for k in range(len(matrices)):
                    couleur = int(abs(matrices[k][i][j]))
                    couleurs.append(couleur)
                if iscolored:
                    draw0[i,j] = tuple(couleurs)
                else:
                    draw0[i,j] = (couleur,couleur,couleur)

                #Permet de tenir l'utilisateur au courant de l'avancement de la création des images
                loading.worker.count += 1
                loading.worker.progress.emit(int((loading.worker.count / loading.worker.total) * 100))

    return image_matrice


