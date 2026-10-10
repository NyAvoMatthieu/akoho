package ferme.configuration;

import bean.ClassMAPTable;

import java.sql.Connection;

public class Compartiment extends ClassMAPTable {

    private String id;
    private String nom;
    private int capacite;
    private String idPoulailler;

    public Compartiment() throws Exception {
        this.setNomTable("COMPARTIMENT");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CMP", "GETSEQCOMPARTIMENT");
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
        this.controlerChamps();
    }

    @Override
    public void controlerUpdate(Connection c) throws Exception {
        super.controlerUpdate(c);
        this.controlerChamps();
    }

    private void controlerChamps() throws Exception {
        if (this.getNom() == null || this.getNom().trim().isEmpty()) {
            throw new Exception("Le nom du compartiment est obligatoire");
        }
        if (this.getIdPoulailler() == null || this.getIdPoulailler().trim().isEmpty()) {
            throw new Exception("Le poulailler du compartiment est obligatoire");
        }
        if (this.getCapacite() <= 0) {
            throw new Exception("La capacité du compartiment doit être strictement positive");
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

    public int getCapacite() {
        return capacite;
    }

    public void setCapacite(int capacite) {
        this.capacite = capacite;
    }

    public String getIdPoulailler() {
        return idPoulailler;
    }

    public void setIdPoulailler(String idPoulailler) {
        this.idPoulailler = idPoulailler;
    }
}