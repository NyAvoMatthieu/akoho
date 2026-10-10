package ferme.acheminement;

import bean.ClassFille;

import java.sql.Connection;

public class RepartitionFille extends ClassFille {

    public static final int SANTE_MIN = 0;
    public static final int SANTE_MAX = 10;

    private String id;
    private String idRepartitionMere;
    private String idCompartiment;
    private int qtt;
    private String sexe;
    private int sante;

    public RepartitionFille() throws Exception {
        this.setNomTable("REPARTITION_FILLE");
        this.setNomClasseMere("ferme.acheminement.Repartition");
        this.setLiaisonMere("idRepartitionMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("RPF", "GETSEQREPARTITIONFILLE");
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
    public String getNomClasseMere() {
        return "ferme.acheminement.Repartition";
    }

    @Override
    public String getLiaisonMere() {
        return "idRepartitionMere";
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
        if (this.getIdCompartiment() == null || this.getIdCompartiment().trim().isEmpty()) {
            throw new Exception("Le compartiment est obligatoire sur chaque ligne de répartition");
        }
        CalculAcheminement.controlerQuantiteLigne(this.getQtt());
        CalculAcheminement.controlerSexe(this.getSexe());
        CalculAcheminement.controlerSante(this.getSante());
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdRepartitionMere() {
        return idRepartitionMere;
    }

    public void setIdRepartitionMere(String idRepartitionMere) {
        this.idRepartitionMere = idRepartitionMere;
    }

    public String getIdCompartiment() {
        return idCompartiment;
    }

    public void setIdCompartiment(String idCompartiment) {
        this.idCompartiment = idCompartiment;
    }

    public int getQtt() {
        return qtt;
    }

    public void setQtt(int qtt) {
        this.qtt = qtt;
    }

    public String getSexe() {
        return sexe;
    }

    public void setSexe(String sexe) {
        this.sexe = sexe;
    }

    public int getSante() {
        return sante;
    }

    public void setSante(int sante) {
        this.sante = sante;
    }
}