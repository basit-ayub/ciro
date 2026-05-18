"""
CIRO Router — SitRep PDF Generation
Endpoint: GET /sitrep/{id}/pdf
Generates an NDMA-style Situation Report PDF for a resolved incident.
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks
import structlog
import os
from pathlib import Path
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

from backend.services import firestore_client

router = APIRouter()
log = structlog.get_logger()

# Setup output directory
PDF_DIR = Path("docs/sitreps")
PDF_DIR.mkdir(parents=True, exist_ok=True)

def build_pdf(situation: dict, action: dict, output_path: str):
    """Builds an NDMA-style Situation Report using reportlab."""
    doc = SimpleDocTemplate(output_path, pagesize=A4)
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle('TitleStyle', parent=styles['Heading1'], alignment=1, fontSize=16, spaceAfter=20)
    heading_style = ParagraphStyle('HeadingStyle', parent=styles['Heading2'], textColor=colors.darkblue)
    normal_style = styles['Normal']
    
    elements = []
    
    # Header
    elements.append(Paragraph("NATIONAL DISASTER MANAGEMENT AUTHORITY (NDMA)", title_style))
    elements.append(Paragraph("SITUATION REPORT (SITREP)", title_style))
    elements.append(Spacer(1, 12))
    
    # Basic Info
    dt_str = datetime.fromisoformat(situation.get("timestamp", datetime.utcnow().isoformat())).strftime("%Y-%m-%d %H:%M:%S")
    elements.append(Paragraph(f"<b>Incident ID:</b> {situation.get('situation_id')}", normal_style))
    elements.append(Paragraph(f"<b>Date/Time:</b> {dt_str}", normal_style))
    elements.append(Paragraph(f"<b>Type:</b> {situation.get('incident_type').replace('_', ' ').title()}", normal_style))
    elements.append(Paragraph(f"<b>Severity:</b> {situation.get('severity')}/5", normal_style))
    elements.append(Spacer(1, 12))
    
    # Incident Summary
    elements.append(Paragraph("1. Incident Summary", heading_style))
    elements.append(Paragraph(situation.get("reasoning_trace", "N/A"), normal_style))
    elements.append(Spacer(1, 12))
    
    # Impact Assessment
    elements.append(Paragraph("2. Impact Assessment", heading_style))
    impact = situation.get("impact_estimate", {})
    impact_data = [
        ["Metric", "Estimate"],
        ["Persons at Risk", str(impact.get("persons_at_risk", 0))],
        ["Vehicles Affected", str(impact.get("vehicles_likely_affected", 0))],
        ["Estimated Duration", f"{impact.get('estimated_duration_min', 0)} mins"]
    ]
    t = Table(impact_data, colWidths=[200, 200])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (1,0), colors.lightgrey),
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
    ]))
    elements.append(t)
    elements.append(Spacer(1, 12))
    
    # Response Actions
    elements.append(Paragraph("3. Coordinated Response Actions", heading_style))
    if action and "plan" in action:
        for step in action["plan"]:
            status = step.get("status", "unknown")
            desc = step.get("action", "Action")
            elements.append(Paragraph(f"• [<b>{status.upper()}</b>] {desc}", normal_style))
    else:
        elements.append(Paragraph("No specific response actions recorded.", normal_style))
        
    doc.build(elements)


@router.get("/{situation_id}/pdf")
async def generate_sitrep(situation_id: str):
    """
    Generate an NDMA-style Situation Report PDF for the given situation.
    """
    situation = firestore_client.get_situation(situation_id)
    if not situation:
        raise HTTPException(status_code=404, detail="Situation not found")
        
    # Attempt to fetch the associated action if it exists (for demo, just fetch generic or None)
    # Ideally, we'd query by situation_id on the actions collection.
    # For now, we'll pass an empty dict if not found easily without a proper query implementation
    action = None
    
    output_filename = f"SITREP_{situation_id}.pdf"
    output_path = str(PDF_DIR / output_filename)
    
    try:
        build_pdf(situation, action, output_path)
        log.info("sitrep_pdf_generated", situation_id=situation_id, path=output_path)
        return {
            "situation_id": situation_id,
            "status": "success",
            "message": "SitRep PDF generated successfully",
            "pdf_url": f"/docs/sitreps/{output_filename}",
            "local_path": output_path
        }
    except Exception as e:
        log.error("sitrep_pdf_failed", error=str(e), situation_id=situation_id)
        raise HTTPException(status_code=500, detail="Failed to generate PDF")

