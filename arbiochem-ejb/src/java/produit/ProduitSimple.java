package produit;

import bean.ClassMAPTable;
import java.sql.Connection;

public class ProduitSimple extends ClassMAPTable{
    private String id;
    private String nom;
    private String idCategorie;
    private int etat;

    public  ProduitSimple(){
        setNomTable("PRODUIT_SIMPLE");
    }

    @Override 
    public String getTuppleID(){
        return id;
    }

    @Override 
    public String getAttributIDName (){
        return "id";
    }

    @Override 
    public void construirePK(Connection c) throws Exception{
        preparePk("PRS","getSeqProduitSimple");
        setId(makePK(c));
    }

    @Override 
    public void controler (Connection c)throws Exception {
        super.controler(c);

        if(nom==null || nom.trim().isEmpty()){
            throw new Exception("Le nom est obligatoire");
        }

        if(idCategorie == null || idCategorie.trim().isEmpty()){
            throw new Exception("La categorie est obligatoire");
        }

    }

    public String getId(){return id;}
    public void setId(String id){this.id = id;}

    public String getNom(){return nom;}
    public void setNom(String nom){this.nom = nom;}

    public String getIdCategorie(){return idCategorie;}
    public void setIdCategorie(String idCategorie){this.idCategorie = idCategorie;}

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
