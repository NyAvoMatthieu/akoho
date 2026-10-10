<%@page import="produit.ProduitSimple"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="user.UserEJB"%>
<%@page import="affichage.PageConsulte"%>

<%
    try {
        UserEJB u = (user.UserEJB) session.getValue("u");

        ProduitSimple objet = new ProduitSimple();
        objet.setNomTable("PRODUIT_SIMPLE");

        PageConsulte pc = new PageConsulte(objet, request, u);
        pc.setTitre("Fiche produit simple");
        pc.getBase();

        String id = pc.getBase().getTuppleID();
        String lien = (String) session.getValue("lien");
%>

<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pc.getTitre() %></h1>
    </section>

    <section class="content">
        <div class="box">
            <div class="box-body">
                <%= pc.getHtml() %>
            </div>
        </div>

        <a href="<%= lien %>?but=produit/produit-simple-saisie.jsp&acte=update&id=<%= id %>"
           class="btn btn-warning">
            Modifier
        </a>

        <a href="<%= lien %>?but=apresTarif.jsp&acte=delete&classe=produit.ProduitSimple&nomtable=PRODUIT_SIMPLE&bute=produit/produit-simple-liste.jsp&id=<%= id %>"
           class="btn btn-danger">
            Supprimer
        </a>
    </section>
</div>

<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script>
    alert('<%= e.getMessage() %>');
    history.back();
</script>
<%
    }
%>
