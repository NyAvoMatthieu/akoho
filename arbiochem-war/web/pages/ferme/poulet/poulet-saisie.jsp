
<%@ page import="affichage.PageInsert"%>
<%@ page import="user.UserEJB" %>
<%@ page import="ferme.poulet.Poulet" %>

<% try{
    UserEJB u = (UserEJB) session.getValue("u");
    String mapping = "ferme.poulet.Poulet";
    String nomTable = "POULET";
    String apres = "ferme/poulet/poulet-fiche.jsp";

    Poulet o = new Poulet();
    o.setNomTable(nomTable);
    PageInsert pi = new PageInsert(o, request, u);
    pi.setLien((String) session.getValue("lien"));
    pi.setTitre("Saisie poulet");

    // En insertion, PageInsert.makeFormulaire() exclut volontairement la
    // colonne identifiant du formulaire (PageInsert.java:88), et
    // Formulaire.getChamp() renvoie null pour un champ absent. L'identifiant
    // est donc produit par Poulet.construirePK() et n'a pas a etre libelle ici.
    // Il n'existe qu'en mode update, ou makeFormulaireUpt() le conserve en
    // lecture seule.
    pi.getFormu().getChamp("nom").setLibelle("Nom");
    pi.getFormu().getChamp("race").setLibelle("Race");

    String[] ordre = {"nom", "race"};
    pi.getFormu().setOrdre(ordre);

    String acte = request.getParameter("acte");
    if (acte != null && acte.equalsIgnoreCase("update")) {
        pi.setTitre("Modification poulet");
        pi.getFormu().getChamp("id").setLibelle("Identifiant");
    }

    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
%>

<div class="content-wrapper">
    <h1><%=pi.getTitre()%></h1>
    <%= acte %>
    <form action="<%=pi.getLien()%>?but=apresTarif.jsp" method="post" name="<%=nomTable%>" id="<%=nomTable%>">
        <%
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%=apres%>">
        <input name="classe" type="hidden" id="classe" value="<%=mapping%>">
        <input name="nomtable" type="hidden" id="nomtable" value="<%=nomTable%>">
    </form>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>