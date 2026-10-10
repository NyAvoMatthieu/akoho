<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageRecherche"%>
<%@ page import="ferme.acheminement.RepartitionFille" %>

<% try{
    RepartitionFille o = new RepartitionFille();
    o.setNomTable("REPARTITION_FILLE");
    String[] listeCrt = {};
    String[] listeInt = {};
    String[] libEntete = {"idCompartiment", "sexe", "sante", "qtt"};
    PageRecherche pr = new PageRecherche(o, request, listeCrt, listeInt, 4, libEntete, libEntete.length);
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));

    if (request.getParameter("id") != null) {
        pr.setAWhere(" and idrepartitionmere='" + request.getParameter("id") + "'");
    }

    String[] colSomme = {"qtt"};
    pr.creerObjetPage(libEntete, colSomme);
    pr.getTableauRecap().setLibeEntete(new String[]{"", "", "", "Somme des quantit&eacute;s"});

    String[] libEnteteAffiche = {"Compartiment", "Sexe", "Sant&eacute;", "Quantit&eacute;"};
    pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>

<div class="box-body">
    <%  if (pr.getTableau().getHtml() != null) {
            out.println(pr.getTableau().getHtml());
        } else { %>
            <center><h4>Aucune donn&eacute;e trouv&eacute;e</h4></center>
    <%  } %>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>