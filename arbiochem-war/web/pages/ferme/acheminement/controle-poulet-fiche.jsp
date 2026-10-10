<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="user.UserEJB" %>
<%@ page import="affichage.PageConsulte" %>
<%@ page import="ferme.acheminement.ControlePoulet" %>
<%@ page import="constante.ConstanteEtat" %>

<% try{
    UserEJB u = (UserEJB)session.getValue("u");
    String lien = (String) session.getValue("lien");

    ControlePoulet o = new ControlePoulet();
    o.setNomTable("CONTROLE_POULET");
    PageConsulte pc = new PageConsulte(o, request, u);
    pc.setTitre("Fiche du contr&ocirc;le de poulet");
    String id = pc.getBase().getTuppleID();

    pc.getChampByName("id").setLibelle("Id");
    pc.getChampByName("daty").setLibelle("Date du contr&ocirc;le");
    pc.getChampByName("typeAntecedent").setLibelle("Type d'ant&eacute;c&eacute;dent");
    pc.getChampByName("idAntecedent").setLibelle("Ant&eacute;c&eacute;dent");
    pc.getChampByName("idLigneAntecedent").setLibelle("Ligne de l'ant&eacute;c&eacute;dent");
    pc.getChampByName("idPoulet").setLibelle("Poulet");
    pc.getChampByName("idMagasin").setLibelle("Lieu");
    pc.getChampByName("quantiteTheorique").setLibelle("Quantit&eacute; th&eacute;orique");
    pc.getChampByName("nbVivant").setLibelle("Nombre de vivants");
    pc.getChampByName("nbMort").setLibelle("Nombre de morts");
    pc.getChampByName("nbPerdu").setLibelle("Nombre de perdus");
    pc.getChampByName("etatlib").setLibelle("&Eacute;tat");
    pc.getChampByName("etat").setVisible(false);

    String[] ordre = {"id", "daty", "typeAntecedent", "idAntecedent", "idLigneAntecedent", "idPoulet", "idMagasin",
            "quantiteTheorique", "nbVivant", "nbMort", "nbPerdu", "etatlib"};
    pc.setOrdre(ordre);

    String pageActuel = "ferme/acheminement/controle-poulet-fiche.jsp";
    String pageRetour = "ferme/acheminement/controle-poulet-liste.jsp";
    String pageApresDelete = "ferme/acheminement/controle-poulet-liste.jsp";
    String classe = "ferme.acheminement.ControlePoulet";
    String pageModif = "ferme/acheminement/controle-poulet-saisie.jsp&acte=update";

    o = (ControlePoulet) pc.getBase();
%>

<div class="content-wrapper">

<h1 class="box-title"><a href=<%= lien + "?but=" + pageRetour%>> <i class="fa fa-angle-left"></i></a><%=pc.getTitre()%></h1>

<div class="row m-0">
    <div class="col-md-3"></div>
    <div class="col-md-6">
        <div class="box-fiche">
            <div class="box">
                <div class="box-body">
                    <%
                        out.println(pc.getHtml());
                    %>
                    <br/>
                    <div class="box-footer">
                        <% if (o.getEtat() < ConstanteEtat.getEtatValider()) { %>
                            <a class="btn btn-primary pull-right" href="<%= lien + "?but=apresTarif.jsp&id=" + id+"&acte=valider&bute="+pageActuel+"&classe="+classe %>">Valider</a>
                            <a class="btn btn-secondary pull-right" href="<%= lien + "?but="+ pageModif +"&id=" + id %>" style="margin-right: 10px">Modifier</a>
                            <a class="btn btn-danger pull-left" href="<%= lien + "?but=apresTarif.jsp&id=" + id+"&acte=delete&bute="+pageApresDelete+"&classe="+classe %>">Supprimer</a>
                        <% } %>
                    </div>
                    <br/>
                </div>
            </div>
        </div>
    </div>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>