package ferme.poulet;

import bean.ClassMAPTable;

import java.sql.Connection;

public class Poulet extends ClassMAPTable {

    private String id;
    private String nom;
    private String race;

    public Poulet() throws Exception {
        this.setNomTable("POULET");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("POU", "GETSEQPOULET");
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
            throw new Exception("Le nom du poulet est obligatoire");
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

    public String getRace() {
        return race;
    }

    public void setRace(String race) {
        this.race = race;
    }
}