package ferme.configuration;

import bean.CGenUtil;
import bean.ClassMAPTable;

import java.sql.Connection;

public class MagasinElevage extends ClassMAPTable {

    public static final String TYPE_LIEU_AEROPORT = "AEROPORT";
    public static final String TYPE_LIEU_POULAILLER = "POULAILLER";

    private String id;
    private String nom;
    private String typeLieu;
    private String idBatiment;
    private int actif;

    public MagasinElevage() throws Exception {
        this.setNomTable("MAGASIN_ELEVAGE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("MLE", "GETSEQMAGASINELEVAGE");
        this.setId(this.makePK(c));
    }

    @Override
    public String getTuppleID() {
        return this.id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);
        if (this.getNom() == null || this.getNom().trim().isEmpty()) {
            throw new Exception("Le nom du lieu est obligatoire");
        }
        this.controlerTypeLieu();
        this.controlerUnicite(c);
    }

    @Override
    public void controlerUpdate(Connection c) throws Exception {
        super.controlerUpdate(c);
        this.controlerTypeLieu();
        this.controlerUnicite(c);
    }

    private void controlerTypeLieu() throws Exception {
        if (this.getTypeLieu() == null || this.getTypeLieu().trim().isEmpty()) {
            throw new Exception("Le type de lieu est obligatoire");
        }
        if (!TYPE_LIEU_AEROPORT.equals(this.getTypeLieu()) && !TYPE_LIEU_POULAILLER.equals(this.getTypeLieu())) {
            throw new Exception("Type de lieu non reconnu : " + this.getTypeLieu() + ". Attendu : " + TYPE_LIEU_AEROPORT + " ou " + TYPE_LIEU_POULAILLER);
        }
        if (TYPE_LIEU_POULAILLER.equals(this.getTypeLieu())
                && (this.getIdBatiment() == null || this.getIdBatiment().trim().isEmpty())) {
            throw new Exception("Un lieu de type " + TYPE_LIEU_POULAILLER + " doit être rattaché à un bâtiment (poulailler)");
        }
    }

    private void controlerUnicite(Connection c) throws Exception {
        MagasinElevage critere = new MagasinElevage();
        critere.setNomTable("MAGASIN_ELEVAGE");
        critere.setNom(this.getNom());
        MagasinElevage[] resultat = (MagasinElevage[]) CGenUtil.rechercher(critere, null, null, c, "");
        for (MagasinElevage autre : resultat) {
            if (!autre.getTuppleID().equals(this.getTuppleID())) {
                throw new Exception("Un lieu nommé " + this.getNom() + " existe déjà");
            }
        }
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getTypeLieu() {
        return typeLieu;
    }

    public void setTypeLieu(String typeLieu) {
        this.typeLieu = typeLieu;
    }

    public String getIdBatiment() {
        return idBatiment;
    }

    public void setIdBatiment(String idBatiment) {
        this.idBatiment = idBatiment;
    }

    public int getActif() {
        return actif;
    }

    public void setActif(int actif) {
        this.actif = actif;
    }
}