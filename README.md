xd7publisher
============

Script to publish RES Workspace Manager apps to XenDesktop 7

Script Powershell de publication d'application depuis un building block Workspace manager vers un delivery group XenDesktop 7.
Ce script requiert l'installation des snapins Powershell suivants (fournis avec les sources XenDesktop 7) : 
-Broker_PowerShellSnapIn
-Citrix.Common.Commands



Pour faire fonctionner ce script : 

-Copier le script sur un serveur RES Workspace Manager.

-Installer les jeux de commandes PowerShell requis.

-Cr�er un building block contenant les applications � publier.

-Editer le script pour sp�cifier le nom d'un des DC XenDesktop 7 (nom de machine ou adresse IP) dans l'ent�te.

-Editer le script pour activer ou non l'ajout du KEYWORDS:Auto dans la description de l'application.

-[Optionnel] Placer le fichier XML building block dans le r�pertoire du script.

-[Optionnel] Passer le chemin vers le building block en param�tre du script.

-Lancer le script.

-Choisir le Delivery Group sur lequel publier les applications (doit �tre pr�-cr��).
