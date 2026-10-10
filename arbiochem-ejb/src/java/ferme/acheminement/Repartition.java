package ferme.acheminement;

import bean.CGenUtil;
import bean.ClassFille;
import bean.ClassMere;
import bean.ClassMAPTable;
import ferme.configuration.Compartiment;

import java.sql.Connection;
import java.sql.Date;
import java.util.HashMap;
import java.util.Map;

public class Repartition extends ClassMere {

    private String id;
    private Date daty;
    private String idControlePoulailler;
    private String idBL;

    public Repartition() throws Exception {
        this.setNomTable("REPARTITION");
        this.setNomClasseFille("ferme.acheminement.RepartitionFille");
        this.setLiaisonFille("idRepartitionMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("REP", "GETSEQREPARTITION");
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
    public String getNomClasseFille() {
        return "ferme.acheminement.RepartitionFille";
    }

    @Override
    public String getLiaisonFille() {
        return "idRepartitionMere";
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        this.controlerRepartition(c);
        return super.createObject(u, c);
    }

    private void controlerRepartition(Connection c) throws Exception {
        this.controlerChamps();
        ControlePoulet controle = this.controlerControlePoulailler(c);
        this.controlerFilles(c, controle);
    }

    private void controlerChamps() throws Exception {
        if (this.getDaty() == null) {
            throw new Exception("La date de la répartition est obligatoire");
        }
        if (this.getIdControlePoulailler() == null || this.getIdControlePoulailler().trim().isEmpty()) {
            throw new Exception("Le contrôle de poulailler est obligatoire pour une répartition");
        }
    }

    private ControlePoulet controlerControlePoulailler(Connection c) throws Exception {
        ControlePoulet critere = new ControlePoulet();
        critere.setNomTable("CONTROLE_POULET");
        critere.setId(this.getIdControlePoulailler());
        ControlePoulet[] resultat = (ControlePoulet[]) CGenUtil.rechercher(critere, null, null, c, "");
        if (resultat.length == 0) {
            throw new Exception("Le contrôle de poulailler " + this.getIdControlePoulailler() + " est introuvable");
        }
        ControlePoulet controle = resultat[0];
        if (!controle.isControlePoulailler(c)) {
            throw new Exception("Le contrôle " + this.getIdControlePoulailler() + " n'a pas été réalisé dans un poulailler");
        }
        if (this.getDaty() != null && controle.getDaty() != null && this.getDaty().before(controle.getDaty())) {
            throw new Exception("La répartition ne peut pas être antérieure au contrôle de poulailler");
        }
        return controle;
    }

    private void controlerFilles(Connection c, ControlePoulet controle) throws Exception {
        RepartitionFille[] filles = (RepartitionFille[]) this.getFille();
        if (filles == null || filles.length == 0) {
            throw new Exception("La répartition doit contenir au moins une ligne");
        }

        String poulailler = this.getPoulaillerDuControle(c, controle);

        int somme = 0;
        Map<String, Integer> occupationParCompartiment = new HashMap<String, Integer>();
        for (RepartitionFille fille : filles) {
            somme += fille.getQtt();
            Integer cumul = occupationParCompartiment.get(fille.getIdCompartiment());
            occupationParCompartiment.put(fille.getIdCompartiment(), fille.getQtt() + (cumul == null ? 0 : cumul));
        }

        CalculAcheminement.controlerSommeRepartition(somme, controle.getNbVivant());

        for (Map.Entry<String, Integer> entry : occupationParCompartiment.entrySet()) {
            Compartiment compartiment = this.getCompartiment(c, entry.getKey());
            if (compartiment == null) {
                throw new Exception("Le compartiment " + entry.getKey() + " est introuvable");
            }
            if (poulailler != null && !poulailler.equals(compartiment.getIdPoulailler())) {
                throw new Exception("Le compartiment " + compartiment.getNom() + " n'appartient pas au poulailler du contrôle de poulailler");
            }
            int total = entry.getValue() + this.getOccupationExistante(c, compartiment.getTuppleID(), this.getTuppleID());
            CalculAcheminement.controlerCapacite(total, compartiment.getCapacite(), compartiment.getNom());
        }
    }

    private String getPoulaillerDuControle(Connection c, ControlePoulet controle) throws Exception {
        ferme.configuration.MagasinElevage lieu = controle.getLieu(c);
        return lieu == null ? null : lieu.getIdBatiment();
    }

    private Compartiment getCompartiment(Connection c, String id) throws Exception {
        Compartiment critere = new Compartiment();
        critere.setNomTable("COMPARTIMENT");
        critere.setId(id);
        Compartiment[] resultat = (Compartiment[]) CGenUtil.rechercher(critere, null, null, c, "");
        return resultat.length == 0 ? null : resultat[0];
    }

    private int getOccupationExistante(Connection c, String idCompartiment, String idRepartitionExclue) throws Exception {
        RepartitionFille critere = new RepartitionFille();
        critere.setNomTable("REPARTITION_FILLE");
        critere.setIdCompartiment(idCompartiment);
        RepartitionFille[] lignes = (RepartitionFille[]) CGenUtil.rechercher(critere, null, null, c, "");
        int total = 0;
        for (RepartitionFille ligne : lignes) {
            if (idRepartitionExclue == null || !idRepartitionExclue.equals(ligne.getIdRepartitionMere())) {
                total += ligne.getQtt();
            }
        }
        return total;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public String getIdControlePoulailler() {
        return idControlePoulailler;
    }

    public void setIdControlePoulailler(String idControlePoulailler) {
        this.idControlePoulailler = idControlePoulailler;
    }

    public String getIdBL() {
        return idBL;
    }

    public void setIdBL(String idBL) {
        this.idBL = idBL;
    }

    }